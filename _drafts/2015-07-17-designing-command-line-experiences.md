----
layout: post
title:  Designing Command Line Experiences
date:   2015-07-17 21:58:50
categories: product design
----

Of all the data stores that I know of, the ones really getting mindshare have
great developer experiences. Data stores like MongoDB and Redis are
the first ones that come to mind. Each of these data stores makes it trival to
get started. Yet for each of them, getting started typically means
invoking a minimal set of commands at the command line. That ability to go from
downloading the binary or building the source and then running a full fleged
data store invokes a wow moment.

While databases are big pieces of software, the same applies to even the
smallest of tools. 

## Build Trust

Building trust means doing what you say you're going to do and if you can't, you
need to be forthcoming and explicit. Being consistent with this behavior across all of the
possible interactions of your tool helps your customers easily identify
when the tool is not working as expected. 

As an example of what not to do, let me use a fake command called `credential`
that will give a user temporary authorization against an API which requires one
parameter, the duration I want the authorization to be valid in hours.

```
$ credential 1
Credential successfully created!
```

Great based on the above command, I'd assume that my credential was created
successfully and I have 1 hours before the system will revoke my access. Now
what if I wanted to increase my duration?

```
$ credential 100
Credential successfully created!
```

Based upon this message, I'd assume that I got a credential that's good for 100
hours. Little did I know that the maximum value for duration is 30 hours. Once 
I go over 30 hours, I'll get error messages interacting with my service
saying that I don't have access any more. That's a miss match between what I
expected and what I actually got. Don't make your users guess!

## Progressive Enhancement

I'm a huge fan of the concept of [progressive
enhancement](https://en.wikipedia.org/wiki/Progressive_enhancement). I'm borrowing this
term from the web design sphere and applying it to command line tools.
Essentially, progressive design is a way of providing the most basic
functionality to all users but if the user has a deeper understanding of the
underlying systems at play, more power and flexibility should be available.

For example, something as mundane as the `ls` command on unix
systems, which lists the contents of a directory, tips its hat to the concept of
progressive enhancement. At the command's most basic level you can just get the
contents of your current working directory:

```
$ ls
Applications    pgadmin.log
```

Knowning what you know about filesystems, you understand that hidden files can
have their names prefaced with a dot and that some of the items that you've
listed in this current directory might have sub-directories. Diving a litte
deeper, I could issue the `ls` command with a few extra options to get that
extra information:

```
$ ls -ap
.vimrc     Applications/    pgadmin.log
```

Be very careful about this concept. Understand the range of abilities of your
users and make sure you target those levels and nothing more. You may not need
everything under the sun from super beginner to ultra-mega-professional.

## Documentation

Documentation tends to be one of the areas that really gets neglected. If someone other than yourself is going to 
interact with, software or not, that's an opportunity for
that individuals to build a perception of your brand. That mental model the
customer is creating could be negative or maybe positive. The point is that by
having excellent docs, your users won't have to guess about how something should
work. Don't think about just one medium of documentation either. There's source
code comments, man pages, help menus and even a purpose built website. I say the
more the better. 

## My Tenants of Great Command Line Experiences

  * trust - trust for a command line tool means that a developer can
    reason about the behavior of your tool.
  * progressive enhancement - understand whos going to use your tool and give
    them some options to get more out of it.
  * documentation - dont make your users guess how your tool is supposed to
    behave.

If you have tenants that you swear by when you create command line tools, drop
me a line, [@neovintage](https://twitter.com/neovintage).
