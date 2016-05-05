---
layout: post
title: "Seldomly Used SQL: bool Aggregate Functions"
date: 2016-05-04 08:01:00
tags: postgres,aggregation
---

Aggregate functions are the cornerstone of performing any type of analysis or reporting on your data that lives within Postgres. The `bool_or` and `bool_and` aggregate functions are ones that I've started to pull out of my toolbox more often. These functions have been particularly useful when I've needed to know if any or all values within a column meets a certain condition and to report on it apporpriately.

## Logical Operators

Before we can dive into the aggregate functions, we first need to discuss logical operators. If you're already familiar with these types of operators, this section will likely be review. Any time you're writing SQL, and are using multiple filters in your where clause, you're using a logical operator. 

```sql
SELECT products.id
     , products.cost
     , sum(orders.amount)
  FROM products 
 INNER JOIN orders
    ON orders.product_id = products.id
 WHERE products.category = 'food'
   AND orders.ordered_at > '2016-01-01 00:00:00'
   AND ( 
         orders.region = 'west'
         or orders.express_delivery = true
       )
 GROUP BY 1, 2
```

In this query we're using both an `AND` operator and an `OR` operator. The `AND` operator means that both conditions need to be true to return a result. In our example, the products that need to have been ordered need to be food items and ordered after the first of the year. The `OR` operator allows for either condition to be true to return a value as part of the result set. In the case of our example, this means orders can be express delivery or have been ordered in the west region. If you need more background on logical operators, the [Postgres documentation](http://www.postgresql.org/docs/current/interactive/functions-logical.html) has a great table on the possible scenarios for all logical operators.

Now imagine being able to take the concept of logical operators and apply that to the rows that are processed as part of a result set. That's what the `bool_or` and `bool_and` aggregate functions do for us. Both functions must take a boolean value as it's parameter. The `bool_or` function will return `true` if at least one of the input values is true. On the other hand, the `bool_and` will return true only if all of the input values are true.

## Example Usage

The best way I've found to explore these concepts is with some example usage. Let's assume I own a warehouse and my warehouse will take orders and, based on the customer, will track the category of the products sold and whether the customer asked for express delivery. My orders table might look something like this:

```sql
CREATE TABLE orders (
  id BIGSERIAL,
  customer_id BIGINT,
  category TEXT,
  express_delivery BOOLEAN 
);
```

Let's assume this is what our initial dataset looks like:

| id  | customer_id | category | express_delivery | 
| --- | ----------- | -------- | ---------------- | 
| 1   | 1           | food     | TRUE             | 
| 2   | 1           | shoes    | TRUE             | 
| 4   | 2           | food     | TRUE             | 
| 5   | 2           | auto     | FALSE            | 
| 6   | 2           | shoes    | FALSE            |
| 7   | 3           | books    | FALSE            | 
| 8   | 3           | auto     | FALSE            | 


### bool_and

Our boss has come in and was curious to know if, based on the category of product, the customers will always ask for express delivery. Also the boss wants to see this breakout against all categories in the database. No problem, let's use the `bool_and` function to make sure that all orders by category are always express delivered:

```sql 
SELECT category
     , bool_and(express_delivery) as always_express
  FROM orders
 GROUP BY 1
```

Our output should look something like this:

| category | always_express |
| -------- | -------------- |
| food     | t              | 
| shoes    | f              | 
| auto     | f              |
| books    | f              |


### bool_or

The boss has come back to us and is curious why so few categories are express delivered. We astutely point out that, we're only looking for instances where *every* delivery in a category is express delivered. A better analysis should be to see which product categories ever get express delivered. This means that if a category has express delivery, even once, we should indicate that it has been for the category. Our SQL and the result set should look like this:

```sql
SELECT category
     , bool_or(express_delivery) as ever_expressed
  FROM orders
 GROUP BY 1
```

| category | ever_expressed |
| -------- | -------------- |
| food     | t              | 
| shoes    | t              | 
| auto     | f              |
| books    | f              |

We now see that `shoes` have been added to the list of products that have been asked to be expressed delivered by customers. The boss has some sense of what to proritize within the warehouse so that food and shoes get out the warehouse door much more quickly.

## Null Values

What happens if our application that's backing the ordering system has an error and we don't record the express delivery field correctly? Let's assume the record got created in the database but the `express_delivery` field was set as `NULL`. Ideally, we'd have a constraint on the field in the database, but for the purposes of this example let's assume we didn't. Let's say our table now looks like this:

| id  | customer_id | category | express_delivery | 
| --- | ----------- | -------- | ---------------- | 
| 1   | 1           | food     | TRUE             | 
| 2   | 1           | shoes    | TRUE             | 
| 4   | 2           | food     | TRUE             | 
| 5   | 2           | auto     | FALSE            | 
| 6   | 2           | shoes    | FALSE            |
| 7   | 3           | books    | FALSE            | 
| 8   | 3           | auto     | FALSE            | 
| 9   | 1           | running  |                  |
| 10  | 1           | food     |                  |

Both the `bool_or` and the `bool_and` functions will treat `NULL` just as that. Our above queries will do one of two things:

1. If other input values in set are not null, then the output will be based on the other values.
2. If all input values in the set are null, then the output of the query will be null as well.

Keep this behavior in mind when you're querying and there is possibility of null values in your data.

## Wrapping Up

I hope you found the `bool_or` and `bool_and` functions as useful as I have. Any time you find yourself starting your analysis with `does any` or `do all` then checkout these functions. If you have other instances where you use these functions, let me know via [twitter](https://twitter.com/neovintage) or [email](mailto:neovintage@gmail.com), I'd love to hear more.

*Edit: Thanks to [@epc](https://twitter.com/epc) and [@floatingatoll](https://twitter.com/floatingatoll) for pointing out a small mistake on one of my headings on the query output. Fixed!*
