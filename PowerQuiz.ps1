<#
.SYNOPSIS
    PowerShell script for a Practice Test Taking Tool.

.DESCRIPTION
    This script defines a PowerShell class 'quiz' for managing quizzes and includes functions to interactively run quizzes,
    display settings, and modify settings through a command-line menu interface.

    To create your own quiz:
    - Locate '.\quiz_data\quiz_template.csv'
    - Using headers as a guide, fill in info
    - Save newly created CSV

    To use custom quiz:
    - Temporarily:
    - Use 'set [OPTION] [VALUE]' command in the running script to edit file path
    - Permanently
    - Edit the object "$data" at the bottom of the script

.INPUTS
    None. You can't pipe objects to PowerQuiz.ps1

.OUTPUTS
    Interactive Menu. Follow input directions.

.NOTES
    File: QuizTool.ps1
    Author: Shawn Wabschall
    Last Update: October2023

.EXAMPLE
    To start the quiz tool, run the script and follow the interactive menu prompts:
    PS C:\> .\QuizTool.ps1

    The menu provides options to run a quiz, display current settings, change settings, and exit the program.

.LINK
    https://github.com/Wabbadabba/PowerQuiz

#>

class Quiz {
    [int]$Length
    [int]$PassingScore
    [bool]$FeedbackMode
    [string]$FilePath
    [pscustomobject]$DataBank

    # Initialization a new instance of the 'quiz' class.
    Quiz([int]$Length, [int]$PassingScore, [bool]$FeedbackMode, [string]$FilePath) {
        $this.Length       = $Length
        $this.PassingScore = $PassingScore
        $this.FeedbackMode = $FeedbackMode
        $this.FilePath     = Resolve-Path -Path $FilePath -ErrorAction SilentlyContinue
        $this.DataBank     = Import-Csv -Path $this.FilePath
    }

    # Grades the quiz based on the final score.
    [void]GradeQuiz ([int]$finalScore) {
        $gradePercentage = ($finalScore / $this.Length) * 100

        Write-Host "You scored a $gradePercentage% ($finalScore / $($this.Length))"

        if ($gradePercentage -ge $this.PassingScore){
            Write-Host "You passed!" -ForegroundColor Green
        }
        else {
            Write-Host "You did not meet the minimum score of $($this.PassingScore)%" -ForegroundColor Red
        }
    }

    # Runs the quiz interactively
    [void]RunQuiz() {
        Write-Host "Input the 'q' key to exit the quiz and return to the main menu`n" -ForegroundColor Green
        $correctCount = 0
        $questionCount = 0

        # Randomizes questions and iterates through the list.
        foreach ($Q in $this.DataBank | Sort-Object { Get-Random }) {
            if ($questionCount -eq $this.Length) { break }
            $questionCount += 1
            Write-Host "$($Q.Question)"
            Write-Host "------------`n"

            $AnswerTable = @{}

            [string[]]$Answers = $Q.Answer_1, $Q.Answer_2, $Q.Answer_3, $Q.Answer_4 | Get-Random -Count 4 | Where-Object { $_ -ne '-' }
            [string[]]$Letters = "ABCD"[0..($Answers.Count - 1)] | Get-Random -Count $Answers.Count
            foreach ($i in 0..($Answers.Count - 1)) {
                $AnswerTable[$Letters[$i]] = $Answers[$i]
            }
            $sortedAnswerTable = $AnswerTable.GetEnumerator() | Sort-Object -Property Name
            $sortedAnswerTable | ForEach-Object { Write-Host "[$($_.Name)] $($_.Value)"}

            $Guess = Read-Host "`nMake a Selection"

            if ($Guess -eq 'q') { 
                Write-Host "`n`n+------------------------------------------+" -ForegroundColor Magenta
                Write-Host "| [!] Exiting Quiz. Returning to main menu |" -ForegroundColor Magenta
                Write-Host "+------------------------------------------+`n`n" -ForegroundColor Magenta
                
                break
            }
            if ($AnswerTable[$Guess] -eq $Q.True_Answer) {
                Write-Host "Correct!`n" -ForegroundColor Green
                $correctCount += 1
            }
            elseif (!$this.FeedbackMode) {
                Write-Host "Incorrect!`n" -ForegroundColor Red
            }
        }
        $this.GradeQuiz($correctCount)
    }
}

# Used to create a prompt without the colon that Read-Host inserts.
function Read-HostCustom {
    param (
        [string]$Prompt
    )
    Write-Host $Prompt -NoNewline
    $Host.UI.ReadLine()
}

# Display Help Menu
# TODO: Make Dynamic
# TODO: Add more info(?)
function Show-HelpMenu {
    
    $output = @"

Core Commands
=============

    Command          Description
    -------          -----------
    run              Runs Loaded Quiz
    show             Show current settings
    show quiz        Show content of the currently loaded quiz
    set              Change settings. Syntax: set [SETTING] [VALUE]
    x , exit         Exit the program

"@
    Write-Host $output
}

# Instead of making a special menu, this just takes the required info, and sets it all into an array of objects
# That array is then displayed with Format-Table.
function Show-Settings {
    param (
        [PSCustomObject]$data
    )

    $helpInfo = @{
        QUIZLENGTH   = @($true,"Length of quiz to be run.")
        PASSINGSCORE = @($true,"Minimum Passing Score. Represented as a Percentage. (Example: '80' would be a minimum passing score of 80%)")
        FEEDBACKMODE = @($true,"If True, will provide feedback after each question about the correctness of the answer provided.")
        FILEPATH     = @($true,"If True, will provide feedback after each question about the correctness of the answer provided.")
        FILESIZE     = @($false,"The total number of questions in the loaded quiz file.")
    }

    $properties = $data | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name

    $Settings = @()

    foreach ($property in $properties) {
        $Settings += [PSCustomObject]@{
            Name        = $property.ToUpper()
            Value       = $data.$property
            CanEdit     = $helpInfo[$property.ToUpper()][0]
            Description = $helpInfo[$property.ToUpper()][1]
        }
    }
    
    $Settings | Format-Table -Property Name, @{Expression={$_.Value};Label="Value"; Align="center"}, @{Expression={$_.CanEdit};Label="CanEdit"; Align="center"}, Description

    Write-Host "Change settings with the 'set' command."
    Write-Host "`nExample: 'set FEEDBACKMODE True'`n"
}

# When the 'run' command is given:
# Run the quiz according to the contents of $data
function Invoke-CommandRun {
    param (
        [PSCustomObject]$data
    )
    $Quiz = [Quiz]::new($data.QuizLength, $data.PassingScore, $data.FeedbackMode, $data.FilePath)
    Write-Host "[+] Created new instance of Quiz()" -ForegroundColor Yellow
    Write-Host "[+]   --QUIZLENGTH   = $($data.QuizLength)" -ForegroundColor Yellow
    Write-Host "[+]   --PASSINGSCORE = $($data.PassingScore)" -ForegroundColor Yellow
    Write-Host "[+]   --FEEDBACKMODE = $($data.FeedbackMode)" -ForegroundColor Yellow
    Write-Host "[+]   --FILEPATH     = $($data.FilePath)" -ForegroundColor Yellow
    Write-Host "[+] Starting Quiz`n" -ForegroundColor Yellow
    $Quiz.RunQuiz()
}

# When the 'Show' command is given:
# Show the raw CSV Content or show current settings
function Invoke-CommandShow {
    param (
        [PSCustomObject]$data,
        [array]$command
    )
    $command = $command.split(' ')
    switch ($command[1]) {
        Quiz { Import-Csv -Path $data.FilePath | Format-Table }
        Default { Show-Settings $data }
    }
}

# When the 'Set' command is given:
# Update the $data object with provided values
function Invoke-CommandSet {
    param (
        [PSCustomObject]$data,
        [array]$command
    )
    Write-Host $command[1]
    switch ($command[1]) {
        QUIZLENGTH{
            if ($command.Length -ge 3) {
                try {
                    [int]$setValue = $command[2]
                    if ($setValue -gt 0 -and $setValue -le $data.FileSize) {
                        $data.QuizLength = $setValue
                        Write-Host "[+] $($command[1].ToUpper()) => $($setValue)`n" -ForegroundColor Yellow
                    } 
                    else { Write-Host "Invalid input. Value must be between 1 and FileSize`n" -ForegroundColor Red }
                }
                catch { Write-Host "Invalid input. Value must be a number`n" -ForegroundColor Red }
            } 
            else { Write-Host "No value given. $($command[1].ToUpper()) not changed`n" -ForegroundColor Red }
        }
        PASSINGSCORE {
            if ($command.Length -ge 3) {
                try {
                    [int]$setValue = $command[2]
                    if ($setValue -gt 0 -and $setValue -le 100) {
                        $data.PassingScore = $setValue
                        Write-Host "[+] $($command[1].ToUpper()) => $($setValue)`n" -ForegroundColor Yellow
                    }
                    else { Write-Host "Invalid input. Value must be between 1 and 100`n" -ForegroundColor Red }
                }
                catch{ Write-Host "Invalid input. Value must be a number`n" -ForegroundColor Red }
            }
            else { Write-Host "No value given. $($command[1].ToUpper()) not changed`n" -ForegroundColor Red }
        }
        FEEDBACKMODE {
            if ($command[2] -eq 'true' -or $command[2] -eq 'false') {
                $data.FeedbackMode = $command[2].ToLower() -eq 'true'
                Write-Host "$($command[1].ToUpper()) => $($data.FeedbackMode)`n"
            }
        }
        FILEPATH {
            if ($command.Length -ge 3) {
                $setValue = $command[2]
                if (Test-Path -PathType Leaf -Path $setValue) {
                    $data.FilePath = $setValue
                    $data.FileSize = (Import-Csv $setValue).Length
                    Write-Host "[+] $($command[1].ToUpper()) => $($setValue)" -ForegroundColor Yellow
                    Write-Host "[+] FILESIZE => $($data.FileSize)" -ForegroundColor Yellow
                }
                else { Write-Host "Path not found. Please ensure path was input correctly" }
            }
        }
    }
    return $data
}


function Show-Banner {
    param (
        [pscustomobject]$data
    )
    $banner = @"
            ____                          ____        _    
           / __ \____ _      _____  _____/ __ \__  __(_)___
          / /_/ / __ \ | /| / / _ \/ ___/ / / / / / / /_  /
         / ____/ /_/ / |/ |/ /  __/ /  / /_/ / /_/ / / / /_
        /_/    \____/|__/|__/\___/_/   \___\_\__,_/_/ /___/
                                                   
====================A Practice Test Taking Tool====================

"@

    Write-Host $banner -ForegroundColor Red
    $titleInfo = @(
        "[ Quiz Loaded           : $($data.FilePath) ]",
        "[ Minimum Passing Score : $($data.PassingScore) ]",
        "[ Feedback Mode         : $($data.FeedbackMode) ]"
    )
    $longestLine = 0
    foreach ($item in $titleInfo) {
        if ($item.Length -gt $longestLine) {
            $longestLine = $item.Length
        }
    }

    $spaceCount = $longestLine + 10

    foreach ($item in $titleInfo) {
        $lengthDiff = $spaceCount - $item.Length
        $modItem = $item.Substring(0,$item.Length - 2) + (' ' * $lengthDiff) + $item.Substring($item.Length - 2)
        Write-Host $modItem -ForegroundColor Magenta
    }
    Write-Host "`n"
    Write-Host "-- Type 'run' to start a new quiz"
    write-Host "-- Type 'show' to see all settings"
    Write-Host "-- Type 'help' to see all commands"
    Write-Host "`n"
}
# Main Menu Display
function Show-Menu {
    param (
        [PSCustomObject]$data
    )

    Show-Banner $data

    while ($true) {
        $command = (Read-HostCustom "PQ > ").split(' ')
        switch ($command[0]) {
            run  { Invoke-CommandRun  $data }
            show { Invoke-CommandShow $data $command}
            set  { $data = Invoke-CommandSet $data $command }
            help { Show-HelpMenu }
            {($_ -eq "x") -or ($_ -eq "exit")} { return }
            Default { continue }
        }
    }
}
$Host.UI.RawUI.ForegroundColor = [System.ConsoleColor]::White


###########################
# EDIT THIS FOR DEFAULTS  #
###########################
$FilePath = ".\quiz_data\quiz_template.csv"
$data = [PSCustomObject]@{
    QuizLength   = 5
    PassingScore = 80
    FeedbackMode = $false
    FilePath     = $FilePath
    FileSize     = @(Import-Csv $FilePath).Count
}

Show-Menu $data
