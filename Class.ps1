# Help
#############################################################################

<#
.SYNOPSIS
My first Powershell/C# class.

.DESCRIPTION


.PARAMETER SourcePath

.INPUTS
None.

.OUTPUTS
None. This script does not generate any output.

.NOTES
AUTHOR: Janne Beate Bakeng, SINTEF
DATE: 04.06.2012

TODO:


.EXAMPLE
#>

## Define the new C# class
$newType = @'
using System;

namespace Stinkerbell
{
    public class MyClass
    {
        public string SayHello(string name)
        {
            string result = String.Format("Hello {0}", name);
            return result;
        }
    }
} //namespace end
'@

## Add it to the powershell session
Add-Type -TypeDefinition $newType

## Show that we can access it like any other .NET type
$greeting = New-Object Stinkerbell.MyClass
$greeting.SayHello("Jannis");