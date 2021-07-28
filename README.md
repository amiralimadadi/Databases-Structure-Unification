# Databases-Structure-Unification

It is usually necessary to have different samples of a database with unique structure in a server. Those databases must have one schema, but you may make some changes in one and forget to make those changes in the rest of them. There are some tools for unifying the databases structure, but I found no pure sql query for that purpose.

It happens often in web application databases, where you are providing a web service to several clients and when you want to release new version, you have to change the structure of database for all clients. 

This repository contains some files to copy the base database structure to another one. There are separated files for database elements like **tables**, **columns**, **views**, **PKs**, **FKs** and etc. There is also a file containing all database elements.

