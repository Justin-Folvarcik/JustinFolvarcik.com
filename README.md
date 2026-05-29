# justinfolvarcik.com

## Welcome!
This repository contains the code for my personal website, justinfolvarcik.com. This project was created with a few explicit rules in mind:
1. No AI code generation - Assistance with concepts and syntax checking is fine, but all code is written by hand!
2. No manual infrastructure - All the infrastructure should be managed by an IaC system (I used Terraform for this).
3. OS-Agnostic - The code should work on any operating system, any architecture.
4. Reproducible - The application should be able to be reproduced readily with no issue.
5. Understanding - I should understand what I am building and why. I should be able to readily explain any line of code in any file.
6. Best practices - Do it right the first time or don't do it at all. If concessions must be made, they must be in the best interest of the project.
7. Low-cost - This site isn't intended to bring in any money, so it can't be too costly.

## What is the stack?
This is a Django application packaged with Docker, uploaded to AWS ECR, and run via lambda function. The database is Aurora Postgres, which will turn off when not in use to save money. This is why the site takes a bit longer to load on first visit - a fair trade in exchange for a negligible monthly bill. This database sits inside a VPC with two private subnets for inbound connections from the lambda function. The Django key itself is managed by SecretsManager, though both it and the database password need to be injected at deployment in order to avoid having to pay for VPC interface endpoints.

## What is the project structure?
It's fairly simple and looks like this:
```
root -
     | manage.py (Django command runner)
     | - terraform -
                   | (terraform configuration files)
     | - justinfolvarcik_com -
                             | (django files)
     
```

## Where is the project so far?
The Terraform configuration is complete (or at least as complete as it needs to be at the moment). Now, it's time to begin work on Django itself.

## What is the end goal?
A site all my own, of course! Writing code is enjoyable to me, as is maintaining infrastructure. Being able to combine the two is an exciting experience, and that alone makes it worth it.

It also doesn't hurt to have my own personal profile and portfolio.

## Why Django?
Because I wanted to try it out for myself and learn a new framework. Plus, I really like Python!

## How can I build this myself?
Coming soon!