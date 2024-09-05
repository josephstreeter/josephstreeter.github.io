# Error Handling

## What is Error Handling

Error handling is a critical to writing PowerShell or any other type of code. Error handling involves anticipating and managing errors or exceptions that may occur during the execution of a script. It is a way to protect resources and to make sure that the process behaves in an expected way, even when the unexpected happens. Handling errors is all about dealing with errors or exceptions and provide meaningful feedback. It is important to stop a process that is not working as expected. Error handling techniques, such as try-catch blocks or error logging, allow exceptions and errors to be identified and delt with in a controlled manner, improving the reliability of the code.

## Terminating vs Non-Terminating Errors

Terminating errors, known as exceptions, terminate the execution process. Non-terminanting errots will cause an error message to be written the error stream, but theh script will continue to execute.

## PowerShell ErrorAction

The following ErrorAction options available with the $ErrorActionPreference and -ErrorAction parameters:

- **Continue:** Writes the error to the pipeline and continues executing the command or script. This is the default behavior in PowerShell.
- **Ignore:** Suppresses error messages and continues executing the command. The errors are never written to the error stream.
- **Inquire:** Pauses the execution of the command and asks the user how to proceed. Cannot be set globally with the $ErrorActionPreference variable.

```console
Action to take for this exception:
Attempted to divide by zero.
[C] Continue  [I] Silent Continue  [B] Break  [S] Suspend  [?] Help (default is
"C"):
```

- **SilentlyContinue:** Suppresses error messages and continues executing the command. The errors are still written to the error stream, which you can query with the $Error automatic variable.
- **Stop:** Displays the error and stops executing the command. This option also generates an ActionPreferenceStopException object to the error stream.
- **Suspend:** Suspends a workflow that can later be resumed. The Suspend option is only available to workflows.

## ErrorActionPreference Variable

The $ErrorActionPreference variable specifies the action to take in response to an error occurring. This allows you to specify, as the name implies, your prefernce for Error Action. If you wanted Error Action for a script to be ```Stop``` for everything you could set the preference varialbe to ```Stop``` and not have to include ```-ErrorAction $Stop``` for each cmdlet. Including the ErrorAction Parameter would only be necessary when you wanted to something different than what you set the prefernce to.

The available values are most of the same ones availble for the ErrorAction parameter:

- Continue (default).
- SilentlyContinue
- Stop
- Inquire

When error action is set to ```Inquire```, the code execution stops and a description is presented to the user. The user is also prompted for what to do next.

```powershell
Action to take for this exception:
Attempted to divide by zero.
[C] Continue  [I] Silent Continue  [B] Break  [S] Suspend  [?] Help (default is "C"):
```

To set the ```$ErrorActionPreference```, issue the following command:

```powershell
$ErrorActionPreference = "SilentlyContinue"
```

## Throw

When the throw command is called, it creates a terminating error. Throw can be used to stop the processing of a command, function, or script.

The throw command used in a script block of an if statement to in a catch block of a try-catch statement to end a process that has experienced an error.

Throw can display any object, such as a user message string or the object that caused the error.

Throw a message:

```powershell
throw "Something went wrong."
```

Output:

```console
Exception: Something went wrong"
```

## Trap

Trap

## Try/Catch/Finally

Try/Catch

```powershell
try
{
    Get-ADUser JMSmith -ErrorAction Stop
}
catch
{
    Write-Error -Message $_.Exception.Message
}
```

Try/Catch/Finally

```powershell
try
{
    Get-ADUser JMSmith -ErrorAction Stop
}
catch
{
    Write-Error -Message $_.Exception.Message
}
```

## References

- ["Everything you wanted to know about Exceptions"](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-exceptions?view=powershell-7.4)
