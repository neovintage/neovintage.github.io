---
layout: post
title: From Postgres to Cassandra
date: 2015-12-29 11:45:00
tags: postgres,cassandra
---


I'm a huge fan of Postgres and I have been for many years along with many [other
people](http://www.craigkerstiens.com/2012/04/30/why-postgres/). It's one of the 
best open-source communities dedicated to building a
fast, standards compliant database. Despite my desire to use Postgres for
everything, some situations require a different style of data store especially
in situations where apps need very high write throughput. To be clear, I see
these two data stores as being complementary not mutually exclusive.

In this post, we'll cover some history and high-level conceptual differences
between Cassandra and Postgres. In subsequent posts we’ll dive into the
specifics of creating tables, data modeling, and data types, just to name a few.
Throughout this series, I'll do my best to apply a set of scenarios where using
Cassandra would make sense. Furthermore, I'll use the most recent versions of
Cassandra Query Language (CQL) and Cassandra to illustrate the appropriate
concepts, 3 and 2.2 respectively

## History

From a historical perspective, Postgres, a featureful and standards compliant
database, has been around since the early 1980s and is written in C. I’m not
going to spend a lot of time spelunking Postgres history but if you’re looking
for more, postgres.org has a great summary. Cassandra, on the other hand, is a
relative new-comer having been released to the public in 2008 and written in
Java. 

Cassandra was originally conceived by Avinash Lakshman and Prashant Malik at
Facebook. The original problem they were trying to solve was storing reverse
indices of messages for their users inboxes. But, additional constraints were
added including the storage of a large amount of data, handling a large rate of
data growth, and to serve the information within strict limits. The initial
release was put up on Google code in 2008. But, it wasn't until 2009 where the
first non-Facebook committer was added to the project and Cassandra started
picking up steam.

The Cassandra codebase eventually moved from Googlecode to an Apache incubator
project ultimately graduating to a top-level Apache project. The community is
still fairly young, as compared to Postgres, but is growing through the backing
of many individuals and corporate sponsors, like [Datastax](http://www.datastax.com) 
and [Instaclustr](https://www.instaclustr.com/).

## Why do you even need Cassandra?

Most applications that I’ve seen usually start out with a Postgres database and
it serves the application very well for an extended period of time. Typically,
based on type of application, the data model of the app will have a table that
tracks some kind of state for either objects in the system or the users of the
application. For the sake of keeping things simple, let’s just call this table
“events”. The growth in the number of rows in this table is not linear as the
traffic to the app increases, it’s typically exponential.

<img src="/public/images/neovintage-postgres-to-cassandra-events-traffic.png"
alt="Traffic vs Events" class="illustration"/>

Over time, the events table will increasingly become the bulk of the data volume
in Postgres, think terabytes, and become increasingly hard to query. In this
situation, it makes sense to move that table out of Postgres and into Cassandra.
Cassandra will be able to handle the nonlinear nature of the events that need to
be created and will scale with minimal changes to the application.

## What Makes Cassandra So Special?

At a high level, relational databases, like Postgres, define the data model in
terms of two-dimensional tables with the dimensions being rows and columns. When
tables are defined, typically the intention is to reduce the amount of data
duplication by normalizing the data model. To illustrate this concept, let's use
an example application that stores event information for users. Each user in the
system will belong to one account and users can have many events. 

<img src="/public/images/neovintage-postgres-to-cassandra-erd.png" alt="Postgres
ERD" class="illustration"/>

Cassandra, on the other hand, is a partitioned key-value store. In some
programming languages, a key-value structure is called a hash or a dictionary.
Each "row", is defined by a unique key with the value being any kind of data
structure itself.

<img src="/public/images/neovintage-postgres-to-cassandra-key-value.png"
alt="Cassandra Key-Value" class="illustration"/>

While Postgres is typically run on just a single instance (I’ll save sharding
and clustering for another post), Cassandra requires that it be run as a cluster
of multiple machines. This is where the partitioned-part of the definition comes
into play. Conceptually, Cassandra looks something like this:

<img src="/public/images/neovintage-postgres-to-cassandra-cluster.png"
alt="Cassandra Cluster" class="illustration" />

Partitioning is done on a partition key. This key defines how data should be
distributed across the cluster. The simplest definition is that it’s the key of
the key-value pair we had defined earlier. But, the partition key can be more
complex than just a single field. Typically, the fields that are used to define
a partition key are hashed together by a partitioner and the resulting value
defines which node in the cluster the data should live. The best part about the
partitioner is that it takes care of the hashing behind the scenes. You can
loosely think of the partition key as you would a primary key in Postgres for
any particular row of information. I’ll dive more into the Cassandra primary key
later on in this series.

As for the value part of the key-value pair, it’s more than just one piece of
information. Instead, the value is actually a column family. A column family is
itself a series of names and values (tuples) that are associated with a
partition key.

<img src="/public/images/neovintage-postgres-to-cassandra-column-family.png"
alt="Cassandra Column Family" class="illustration" />

In Postgres, depending on the table constraints, when a record is created, each
row has a defined value for each column. In a column family in Cassandra, only
those columns that have data as part of the column family are actually written
to the data store. I talk about column families here because that was what they
were originally called in versions of Cassandra prior to 3.0. From 3.0 forward,
column families are called tables. This brings the concept a little closer to
Postgres and SQL.

## What's Next

This was a very high level overview of Cassandra touching on the history and
conceptual architecture with one main use case for using Cassandra in concert
with Postgres. There's way more that I didn't cover, topics like data 
modeling, querying and best practices which can be lengthy posts in their own
right.

If you have any questions or comments please feel free to reach out to me via
[email](mailto:neovintage@gmail.com) or
[twitter](https://twitter.com/neovintage).
