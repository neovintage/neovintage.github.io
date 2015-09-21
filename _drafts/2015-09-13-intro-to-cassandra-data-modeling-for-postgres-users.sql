----
layout:     post
title:      From Postgres to Cassandra: Intro to Data Modeling
date:       2015-10-01 12:02:00
categories: cassandra postgres modeling
----

I'm a huge fan of Postgres. I have been for quite a while but as data volumes have grown with certain projects, I've found myself reaching the limits of what Postgres can do. This is where Cassandra comes into play.

fundamental difference- postgres is a relational database while cassandra is a key-value store with relational tendancies

talk about how you need to do more up front planning about the data rather than after the fact in relational databases

deconstruct the create table statement

Recommendation is to start out with relational before going to cassandra
