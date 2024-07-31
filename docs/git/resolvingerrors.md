# Resolving Errors

## Divergent Branch Error

***Describe the error***

```bash
git switch <feature branch>
git rebase main

# If main/master is not protected, you can then merge into that branch. Otherwise, create a PR to merge the changes into main/master.
git switch main
git merge feature
```
