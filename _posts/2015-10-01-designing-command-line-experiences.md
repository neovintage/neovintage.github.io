---
layout: post
title: Designing Command Line Experiences
date: 2015-10-01 12:45:00
categories: product design
---


The best software products are those that give their customers great
experiences. The opportunity to delight customers or users of your products can
happen during any interaction. For example, Slack’s awesome [onboarding
process](https://www.useronboard.com/how-slack-onboards-new-users/)
is great for setting expectations within the app. While web and mobile apps tend
to get all of the limelight relative to experience design, creating exceptional
command line experiences can be just as unique and challenging. Command line
tools can be large pieces of software, like the gcc compiler, to the smallest of
tools like the `ls` command that lists the contents of the current working
directory on Unix systems. The famously titled, [“Art of Unix
Programming”](http://www.amazon.com/UNIX-Programming-Addison-Wesley-Professional-Computng/dp/0131429019/ref=sr_1_1?ie=UTF8&qid=1443728638&sr=8-1&keywords=art+of+unix+programming),
distills a [philosophy](http://catb.org/esr/writings/taoup/html/ch01s06.html) from the way programs and interfaces were built for Unix
systems. One of my favorite Unix philosophy tenants is building programs that do
one thing and doing it well. While the [Unix
philosophy](http://catb.org/esr/writings/taoup/html/ch01s06.html) is a good base for
defining a good command line experience, I’ve found that I’ve needed a few more
guiding principles.

## Build Trust

Building trust means doing what you say you're going to do and if you can't, you
need to be forthcoming and explicit. Being consistent with this behavior across
all of the possible interactions of your tool helps your customers easily
identify when the tool is not working as expected. 

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
hours. Little did I know that the maximum value for duration is 30 hours. Once I
go over 30 hours, I'll get error messages interacting with my service saying
that I don't have access any more. That's a mismatch between what I expected and
what I actually got. Don't make your users guess!

## Progressive Enhancement

I'm a huge fan of the concept of [progressive
enhancement](https://en.wikipedia.org/wiki/Progressive_enhancement). I'm
borrowing this term from the web design sphere and applying it to command line
tools. Essentially, progressive design is a way of providing the most basic
functionality to all users but if the user has a deeper understanding of the
underlying systems at play, more power and flexibility should be available.

For example, let’s use something as mundane as the `ls` command on unix systems.
This command tips its hat to the concept of progressive enhancement. At the
command's most basic level you can just get the contents of your current working
directory:

```
$ ls
Applications    pgadmin.log
```

Knowing what you know about filesystems, you understand that hidden files can
have their names prefaced with a dot and that some of the items that you've
listed in this current directory might have sub-directories. Diving a little
deeper, I could issue the `ls` command with a few extra options to get that
extra information:

```
$ ls -ap
.vimrc     Applications/    pgadmin.log
```

Be very careful about this concept. Understand the range of abilities of the
users that you expect to use your tool and make sure you target those levels and
nothing more. You may not need everything under the sun from super beginner to
ultra-mega-professional.

## Documentation

Documentation can take many forms, from the help text that gets outputted when a
command is run incorrectly, to the source code comments and even the website
that houses the extended information on how to operate the command, just to name
a few. Unfortunately, in practice, building good documentation tends to be one
of the areas that really gets neglected. Now there’s something to be said for a
user not having to read the full set of docs to figure out your command line
tool. If they have to go to the docs to figure it out, then the experience is
largely a failure. In that sense, I view documentation as addressing a few other
areas for the user. The first of which is discoverability around what your
command line tool can do and the second is building you or your company’s brand. 

Web site and mobile apps have it way easier when it comes to discoverability.
They have all sorts of navigation menus, notifications and graphical elements
like font sizes to work with. However, documentation can provide a level of
discoverability that you might not get when a user interacts with your tool on a
daily basis. Let’s use the [ngrok](https://ngrok.com/) tool as an example. Ngrok is a tool that allows
you to create secure introspected tunnels to your local machine. What I love
about it is how easy it is to get started and how it tells you what you need to
do via documentation. For example, you can go to the ngrok site, download the
binary, unzip and issue the command `ngrok`. What’s happens next is fantastic, a
full set of information on what ngrok is, examples of how to use it, version
numbers and commands get published in the terminal. From a discoverability
perspective, I know now what ngrok can do and how to get extra help. 

The second front where documentation can help is on the branding side. How
thorough are you in your docs? Do you provide examples? Do you tell users where
to go if they have more questions? Going back to our ngrok example, the
[documentation on their website](https://ngrok.com/docs) does a good job of answering all of the questions
above and more. To me, the docs convey a sense of quality and that contributes
to how I may perceive the quality of the command line tool itself and how the
company conducts itself. When it comes to branding, every touch point a customer
has with anything the company produces results in the customer building a
profile of what that company stands for. Docs are a great way of implicitly
communicating that value.

## My Tenants of Great Command Line Experiences

The Unix philosophy is a great starting point for understanding what it takes to
build good command line experiences. I highly recommend reading through the “Art
of Unix Programming”. On top of that, I’ve found that build command line tools
takes a little bit more:

  * Trust - trust for a command line tool means that a developer can
    reason about the behavior of your tool.
  * Progressive enhancement - understand who’s going to use your tool and give
    them some options to get more out of it.
  * Documentation - use it to teach and delight your users on what your tool can
    do.

While these are the tenants that I follow, I’m sure there’s more out there. If
you have principles that you swear by when you create command line tools, drop
me a line, [@neovintage](https://twitter.com/neovintage), or comment over on
[Hacker News](). 
