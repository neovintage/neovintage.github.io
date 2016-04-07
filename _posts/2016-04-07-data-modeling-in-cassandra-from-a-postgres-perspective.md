---
layout: post
title: Data Modeling in Cassandra from a Postgres Perspective
date: 2016-04-07 10:09:00
tags: postgres,cassandra
---


In my [previous post](http://neovintage.org/2015/12/29/from-postgres-to-cassandra/), I introduced some very high level conceptual differences between Postgres and Cassandra. I also refereneced one pattern that I've seen where it makes sense to use the two systems together. When you have one very large table in Postgres where the disk size is measured in terabytes, and that's after it's been fully vacuumed, it might make sense to bring Cassandra into your architecture. Trust me, that one very large table can create operational headaches over time in Postgres. But how easy is it to model my schema in Cassandra if all I know is Postgres? Cassandra has its own SQL-like dialect called Cassandra Query Language (CQL) that mirrors many of the semantics of SQL but that's where it stops. You'll need to know how SQL and CQL differ and how to model the data properly in Cassandra.

## Moving the Large Events Table

For the purposes of this exercise, let's assume that my data model in Postgres has three different tables: users, accounts and events. The data definition for this schema in SQL would look something like this:

{% highlight sql %}
CREATE TABLE users (
  id bigserial,
  name text,
  email text,
  encrypted_password text,
  created_at timestamp without time zone,
  updated_at timestamp without time zone
);

CREATE TABLE accounts (
  id bigserial,
  name text,
  owner_id bigint,
  created_at timestamp without time zone,
  updated_at timestamp without time zone
);

CREATE TABLE events (
  user_id bigint,
  account_id bigint,
  session_id text,
  occurred_at timestamp without time zone,
  category text,
  action text,
  label text,
  attributes jsonb
);
{% endhighlight %}

This is pretty straight forward. Our application has multiple users that belong to an account and, as our users do things inside of our application, we've instrumented their interactions to send events to the database to be stored in the events table. Over time this setup has worked well but now the amount of data inside the events table has ballooned. The growth of a table like events is typically non-linear as compared to data growth for the other tables in the schema. Now let's walk through how we move the events table out to Cassandra.

## Creating the Initial Cassandra Cluster

Cassandra can be thought of as one cluster but that one cluster can have many grouping of nodes called data centers. Let’s assume we were going to create our Cassandra cluster using Amazon Web Services (AWS). We could have one cluster in AWS and then create datacenters in different regions. For example, my topology could have two data centers, one in us-east another in us-west and I could have five nodes in each.

<img src="/public/images/neovintage-data-modeling-cassandra-datacenters.png" alt="Cassandra Data Centers" class="illustration"/>

To create the cluster, we’ll need to define some properties and stuff them into a couple of different configuration files. We also need to make sure that we create each of the nodes ahead of time and that Cassandra is installed on each of them. I’m going to gloss over those details for now but if you need more help, a [decent tutorial](http://foorious.com/ikn/devops/cassandra-cluster-trusty-install/) on setting up a multi-node cassandra cluster should get you set up. 

Assuming we’ve got the initial installation complete, for the sake of continuing my example, I’ve updated the file `/etc/cassandra/cassandra-rackdc.properties` to name the data center based on the AWS region I’m hosting each of the nodes in the data centers:

```
dc=us-east
rack=rac101
```

The data center names are important when we start building our Cassandra schema. For each of the nodes, I've created in the US East region in AWS, I've added the `rackdc.properties` with the appropriate `dc`. When creating this file for the nodes in my other region, US West, I'd set the `dc` equal to `us-west`. Note that these names could be anything I wanted them to be, but I like them to mirror the AWS regions so that I know what I'm dealing with.

## Designing the Cassandra Schema

Before we can create our events table in Cassandra, we need to create a keyspace. A keyspace is roughly analogous to a database in Postgres.

A Postgres instance can have many databases and, in turn, each of those databases can have multiple schemas. Schemas in Postgres can be defined, at a basic level, as a named collection of tables, views and other objects. A keyspace can be thought of as a Postgres database with only one schema. CQL even has `CREATE SCHEMA` as an alias for `CREATE KEYSPACE`. When we define the keyspace in Cassandra, we’re setting up the rules for the cluster topology as well as how data gets replicated between the nodes.

{% highlight cql %}
CREATE KEYSPACE IF NOT EXISTS neovintage_prod
       WITH REPLICATION = { ‘class’: ‘NetworkTopologyStrategy’, ‘us-east’: 3 };
{% endhighlight %}

In the above example, we’re using the network topology strategy and the data center of `us-east` has a replication factor of 3. 

### Creating a Cassandra Table

Now that we’ve got our keyspace created, it’s time to actually define the events table. The semantics of creating a table look the same in Cassandra as it does in Postgres but that’s where it ends.

{% highlight cql %}
CREATE TABLE neovintage_prod.events (
  user_id bigint primary key,
  account_id bigint,
  session_id text,
  occurred_at timestamp without timezone,
  category text,
  action text,
  label text,
  attributes map<text, text>
);
{% endhighlight %}

Many of the data types from Postgres map to the data types in Cassandra but not all. Here’s a list of what you’ll find in terms of differences between the two:

| Postgres Type | Cassandra Type |
|-------------- | -------------- |
| bigint | bigint |
| int | int |
| decimal | decimal |
| float | float |
| text | text |
| varchar(n) | varchar |
| blob | blob |
| json | n/a |
| jsonb | n/a |
| hstore | map<type, type> |

One of the biggest challenges I’ve had converting over Postgres models to Cassandra has been the JSON data types from Postgres. Cassandra doesn’t really handle nested data structures very well. I take that back, it doesn’t at all. The best proxy for that is the collection type `map`. `map` is itself a collection of key/value pairs that can be used to store information in the column family. Typically if you’re going to save JSON, the prevailing best practice is to serialize that information into a blob or use a single layer with the map collection type. Do check out the rest of the collection [data types](http://docs.datastax.com/en/cql/3.3/cql/cql_reference/cql_data_types_c.html) in Cassandra, there’s things like set and list.

### SQL Primary Key != CQL Primary Key

Cassandra primary keys are nothing like Postgres primary keys. In Postgres, when you create a primary key, you’re explicitly telling the database that the fields you’ve defined for the primary key contain unique, nonnull values. On top of that, an index gets created based on the primary key to enforce uniqueness. Cassandra’s primary key doesn’t do any of that. Generally speaking the purpose of the primary key in Cassandra is to order information within the cluster.

The primary key is a very loaded term in CQL. First and foremost, the primary key is used by Cassandra to distribute the data amongst the nodes in the cluster. This is called the partition key. If you desire to have a composite primary key, the first set of columns become the partition key. A composite primary key with multiple fields for the partition key would look like this, where the `user_id` and `account_id` are the partition key:

{% highlight cql %}
CREATE TABLE neovintage_prod.events (
  user_id bigint,
  account_id bigint,
  …
  occurred_at timestamp
  PRIMARY KEY ((user_id, account_id), session_id, occurred_at)
);
{% endhighlight %}

Second, the remaining columns within a primary key definition are used for clustering. Clustering in the Cassandra sense means how the data in the defined columns are stored on disk. In the above example, Cassandra will sort by session_id first and then the occurred_at field second. You do have the ability to change the ordering on disk by using the `CLUSTERING ORDER BY` [syntax](http://docs.datastax.com/en/cql/3.3/cql/cql_reference/refClstrOrdr.html) at the time of table creation.

The syntax for composite primary keys can be fairly complicated but if you only have one column as the primary key, that one column will be used as both the partition key and the clustering column. This double meaning for the primary key in Cassandra is why it’s such a loaded term.

### Eventually Consistent

I can’t stress enough that the primary keys within Cassandra enforce eventual consistency. Unlike Postgres primary keys, eventual consistency could lead to unexpected results with your data. Let’s walk through a contrived scenario to understand what could happen. Imagine that I have a table in my production keyspace that tracks the amount of hits a page on my site gets. Again, this is contrived and not something you’d actually set up in a schema, this is only to illustrate eventual consistency:

{% highlight cql %}
CREATE TABLE neovintage_prod.hits (
  page_name text
  count bigint
  day_of_event timestamp
  PRIMARY KEY (day_of_event, page_name)
);
{% endhighlight %}

If we have multiple clients attached to the cluster and each of those clients is attached to a different node, this is where the problem starts to manifest itself. A client on node1 reads the number of hits for the page name ‘welcome’, which happens to be 10, and tries to increment it by 2 to 12. At the same time, a second client on node2 read the value of the hits for the welcome page, which is 10, but instead tries to increment the count by 1 to 11. Since the second client was the last one that wrote information to Cassandra, if no other updates are made to that record, then the hit count of 11 will get propagated amongst all of the nodes in the cluster. Even though this was a made-up example, being mindful of eventually consistency is super important.

A lot of careful thought needs to be put upfront in your table design because you need to make sure that the primary key is specific enough to the point where it’s highly unlikely that you’ll run into collisions. My general rule is if you need some level of consistency, don’t do it in Cassandra or redesign the schema so you don’t run into problems. 

## Next Steps

I’ve gone through a very terse walkthrough of converting over an events table in a Postgres database to Cassandra. There’s still a lot more to talk about about including best practices and what happens under the hood. If you’re up for digging into some documentation, I’d recommend checking out the very complete docs over at Datastax. Otherwise, if you have questions, comments or other ways of thinking about data modeling in Cassandra, reach out to me via [twitter](https://twitter.com/neovintage) or [email](mailto:neovintage@gmail.com). Cheers!

