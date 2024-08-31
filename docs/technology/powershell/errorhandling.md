# Error Handling

## What is Error Handling

Error handling is a crucial aspect of programming that involves anticipating and managing errors or exceptions that may occur during the execution of a script or program. It is a way to protect resources and ensure that the program behaves as expected, even when unexpected situations arise. Error handling allows developers to gracefully handle errors, provide meaningful feedback to users, and prevent the program from crashing or causing unintended consequences. By implementing error handling techniques, such as try-catch blocks or error logging, developers can identify and handle errors in a controlled manner, improving the reliability and robustness of their code.

## The Difference Between Terminating and Non-Terminating Errors

Terminating errors, known as exceptions, terminate the execution process. Non-terminanting errots will cause an error message to be written the error stream, but theh script will continue to execute.

## PowerShell ErrorAction

The following ErrorAction options available with the $ErrorActionPreference and -ErrorAction parameters:

- **Continue:** Writes the error to the pipeline and continues executing the command or script. This is the default behavior in PowerShell.
- **Ignore:** Suppresses error messages and continues executing the command. The errors are never written to the error stream.
- **Inquire:** Pauses the execution of the command and asks the user how to proceed. Cannot be set globally with the $ErrorActionPreference variable.
- **SilentlyContinue:** Suppresses error messages and continues executing the command. The errors are still written to the error stream, which you can query with the $Error automatic variable.
- **Stop:** Displays the error and stops executing the command. This option also generates an ActionPreferenceStopException object to the error stream.
- **Suspend:** Suspends a workflow that can later be resumed. The Suspend option is only available to workflows.

## Error Action Preference

Error Action Preference

## Throw

Throw

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

## References

- ["Everything you wanted to know about Exceptions"](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-exceptions?view=powershell-7.4)
