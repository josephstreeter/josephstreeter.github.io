---

title:  VIM Undo and Line Number Tricks
date:   2012-10-18 00:00:00 -0500
categories: IT
---






Found a couple handy VIM tricks on the www.vim-fu.com site.

Undo

I haven't posted a trick in a while, so here's a good one to know.

Ever start working on a file in command mode and then hit the caps key without realizing it.  Wham! All sorts of un-expected things can happen before you know it.  What do you do then? You could use q! to exit without saving, then start over, but there is a more graceful way now.
```powershell
:e!
```
This will rollback ALL changes to the edited file without having to exit VIM.



This is a cool interface to VIM's undo/redo list:
```powershell
:earlier 2m    <- back by 2 minutes
:later 30s      <-forward 30 seconds
:undo 5         <- go back 5 changes
:undolist        <- show entire undo/redo list
```

Add line numbers
I often find it helpful to have line numbers when editing.
```powershell
:set number, also :set nu   (turns on)
:set nonumber, also :set nonu (turns off)
```


