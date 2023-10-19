<#
    .SYNOPSIS
    Runs practice quizzes in the terminal

    .DESCRIPTION
    The Practice_Quiz.ps1 script allows for users to run through quizzes.

    To create your own quiz:
    - Locate '.\quiz_data\quiz_template.csv'
    - Using headers as a guide, fill in info
    - Save newly created CSV

    To use custom quiz:
    - Temporarily:
      - Use Settings menu to edit file path
    - Permanently
      - Edit the variable at the top of the script called "$quiz_file"

    .INPUTS
    None. You can't pipe objects to Practice_Quiz.ps1

    .OUTPUTS
    Interactive Menu. Follow input directions.

    .EXAMPLE
    PS> .\Practice_Quiz.ps1

    .NOTES
    

#>

using namespace System.Management.Automation.Host

#############################################
# DEFAULT CONFIGS
# Edit these to change default settings
#############################################
$quiz_file = ".\quiz_data\quiz_template.csv"
$size = 2
$passing_score = 80
#############################################

function Get-Question {
    param (
        [parameter(Mandatory=$true)]
        [System.Object]$question
    )
    $script:answer_bank = @{}
    $options = @("A","B","C","D")
    foreach ( $num in (1..4 | Sort-Object {Get-Random})){
        $ans = $question.("Answer_" + $num)
        if ( $ans -ne '-'){
            $answer_bank.Add(
                $options[$answer_bank.count],
                $ans
            )
        }
    }
        # Output Question and Answer Options
        
        Write-Host "$($quiz.IndexOf($question) + 1). $($question.Question)"
        foreach ($entry in ($answer_bank.GetEnumerator() | Sort-Object -Property Name)){
            Write-Host "   $($entry.Key). $($entry.Value)"
        }
        Write-Host ""
}

function New-Quiz {
    param (
        [string]$file
    )
    $quiz = Import-Csv $file | Sort-Object {Get-Random}
    $correct = 0

    Clear-Host
    for ($i = 0; $i -lt $size; $i++) {
        $current_question = $quiz[$i]
        Get-Question $current_question
        $rtn = Read-Host "Make a Selection"
        if ($answer_bank.ContainsKey($rtn)) {
            if ($answer_bank[$rtn] -eq $current_question.True_Answer){
                Write-Host "Correct!`n" -ForegroundColor Green
                $correct++
            }else {
                Write-Host "Incorrect`n" -ForegroundColor Red
            }
        }
    }
    $grade = ($correct / $size) * 100
    Write-Host "You scored a $grade% ($correct / $size)"
    if ($grade -ge $passing_score){
        Write-Host "You passed!"
    }else{
        Write-Host "You did not meet the minimum score of $passing_score%"
    }
}

function Show-Settings{
    Clear-Host
    Write-Host "========Practice Test========"
    Write-Host "    Loaded       : $($quiz_file.Split('\')[-1].Split('.')[0])"
    Write-Host "    Size         : $size"
    Write-Host "    Passing Score: $passing_score%"
    Write-Host "=============================`n`n"
}

function Show-SettingsMenu{
    Show-Settings
    $file = [ChoiceDescription]::new('&File','Change Quiz Source Filepath')
    $q_size = [ChoiceDescription]::new('&Size','Change Number of Questions Asked')
    $Pass = [ChoiceDescription]::new('&Passing Score','Change Score needed to Pass')
    $back = [ChoiceDescription]::new('&Back','Back to Main Menu')
    $options = [ChoiceDescription[]]($file,$q_size,$back)
    $choice = $host.UI.PromptForChoice("Select Option","",$options,-1)

    switch ($choice) {
        0 { 
            $quiz_file = Read-Host "Provide path to Quiz File"
            Show-SettingsMenu
        }
        1 { 
            $size = Read-Host "How long would you like the test to be?"
            Show-SettingsMenu
        }
        2 { 
            Show-Menu 
        }
    }
}

function Show-Menu {
    param (
        [string]$Title = "Practice Test"
    )

    Show-Settings
    Write-Host "Options:"
    Write-Host "--Run a new quiz"
    Write-Host "--Change Settings"
    Write-Host "--Exit the program"
    Write-Host "============================="

    $run = [ChoiceDescription]::new('&Run','Run a quiz')
    $settings = [ChoiceDescription]::new('&Settings','Edit Settings')
    $exit = [ChoiceDescription]::new('E&XIT','Exit the Program')
    $options = [ChoiceDescription[]]($run,$settings,$exit)
    $choice = $host.UI.PromptForChoice("Select Option","",$options,-1)

    switch ($choice){
        0 {New-Quiz $quiz_file}
        1 {Show-SettingsMenu}
        2 {break}
    }
}

Show-Menu