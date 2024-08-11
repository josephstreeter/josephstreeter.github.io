# Terminology

The following will cover a number of terms that will be encountered thoughout the use of Git and related services. The relationship of these terms is somewhat circular, so you may have to read them all and then read them again to understand how they relate to each other.

- **Index** - A staging area where changes are stored before being committed to the ***working tree.***
- **Working Tree** - The directory, including all its files and sub-directories that make up a repository. The top level of a working tree can be identified by the existence of a .git directory.
- **Commit** - A snapshot of the working tree at the time the commut was created. When a commit is created, the state of ***HEAD*** becomes that commit's parent. It is this parent relationship that is the basis for the concept of "source control."
- **HEAD** - Defines what is currently checked out. HEAD symbolically refers to a ***branch*** that is checked out. If a specific ***commit*** is checked out (Detached HEAD), HEAD referes to that ***commit*** only. 
- **Repositoy** - A repository is a collection or ***commits*** and defines which one is the ***HEAD***.
- **Branch** - A name for a ***commit*** and it's parentage that defines history. 
- **Tag** - Similar to a branch, it names a particular commit and can have it's own description.
- **Master/Main** - A branch that represents the mainline of development for a repository. Typically known as either ***master*** or ***main***, may also be named ***trunk***.
