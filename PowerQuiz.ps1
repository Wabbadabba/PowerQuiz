<#
    .SYNOPSIS
    Runs practice quizzes in the terminal

    .DESCRIPTION
    The PowerQuiz.ps1 script allows for users to run through quizzes.

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
    None. You can't pipe objects to PowerQuiz.ps1

    .OUTPUTS
    Interactive Menu. Follow input directions.

    .EXAMPLE
    PS> .\PowerQuiz.ps1

    .NOTES
    Author: Shawn Wabschall
    Last Update: October2023
    
    .LINK
    https://github.com/Wabbadabba/PowerQuiz

#>

using namespace System.Management.Automation.Host

"$data_file = Get-Content -Raw .\data.json | ConvertFrom-Json"

$loaded_quiz = $data_file[0]
$quiz_file = $loaded_quiz.FileName


#############################################
# DEFAULT CONFIGS
# Edit these to change default settings
#############################################
$size = 2
$passing_score = 80
$feedback = $false
#############################################

function Show-Feedback {
    param (
        [Parameter(Mandatory=$true)]
        [string]$response,

        [parameter(Mandatory=$true)]
        [ValidateSet("pos","neg")]
        [string]$type
    )

    if ($feedback -eq $true) {
        if ($type -eq "pos") {
            Write-Host $response -ForegroundColor Green
        }
        elseif ($type -eq "neg") {
            Write-Host $response -ForegroundColor Red
        }
    }
}

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
    # Main Quiz function

    param (
        [string]$file
    )

    $filename = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "quiz_data") -ChildPath $file
    $quiz = Import-Csv $filename | Sort-Object {Get-Random}
    $correct = 0

    Clear-Host
    for ($i = 0; $i -lt $size; $i++) {
        $current_question = $quiz[$i]
        Get-Question $current_question
        $rtn = Read-Host "Make a Selection"
        if ($answer_bank.ContainsKey($rtn)) {
            if ($answer_bank[$rtn] -eq $current_question.True_Answer){
                # Write-Host "Correct!`n" -ForegroundColor Green
                Show-Feedback -response "Correct!`n" -type "pos"
                $correct++
            }
            else {
                # Write-Host "Incorrect`n" -ForegroundColor Red
                Show-Feedback -response "Incorrect`n" -type "neg"
            }
        }
        else {
            # Write-Host "Incorrect`n" -ForegroundColor Red
            Show-Feedback -response "Incorrect`n" -type "neg"
        }

        Write-Host "`n═════════════════════════════════════════`n" -ForegroundColor Yellow
    }
    $grade = ($correct / $size) * 100
    Write-Host "You scored a $grade% ($correct / $size)"
    if ($grade -ge $passing_score){
        Write-Host "You passed!" -ForegroundColor Green
    }else{
        Write-Host "You did not meet the minimum score of $passing_score%" -ForegroundColor Red
    }

}

function Show-Settings{
    # Displays Current Settings.
    if ($feedback -eq $true){
        $feedback_mode = "ON"
    }
    else {
        $feedback_mode = "OFF"
    }

    Clear-Host
    Write-Host "╔═══════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║             Practice Test             ║" -ForegroundColor Yellow
    Write-Host "╚═════════════════╦═════════════════════╝" -ForegroundColor Yellow
    Write-Host "    Quiz Loaded   ║ $($loaded_quiz.Name)" -ForegroundColor Cyan
    Write-Host "    File Path     ║ $quiz_file" -ForegroundColor Cyan
    Write-Host "    Size          ║ $size" -ForegroundColor Cyan
    Write-Host "    Passing Score ║ $passing_score%" -ForegroundColor Cyan
    Write-Host "    Feedback Mode ║ $feedback_mode" -ForegroundColor Cyan
    Write-Host "══════════════════╩══════════════════════`n" -ForegroundColor Yellow
}

function Show-SettingsMenu{
    # Displays the Settings Menu, and allows for the changing of settings 

    Show-Settings
    $Load = [ChoiceDescription]::new('&Load','Load new Quiz')
    $q_size = [ChoiceDescription]::new('&Size','Change Number of Questions Asked')
    $pass = [ChoiceDescription]::new('&Passing Score','Change Score needed to Pass')
    $feed = [ChoiceDescription]::new('Fee&dback Mode','Feedback Mode displays Correct or Incorrect answers')
    $back = [ChoiceDescription]::new('&Back','Back to Main Menu')
    $options = [ChoiceDescription[]]($load,$q_size,$pass,$feed,$back)
    $choice = $host.UI.PromptForChoice("Select Option","",$options,-1)

    switch ($choice) {
        0 { 
            $loaded_quiz = Set-QuizData -data_file $data_file
            $quiz_file = $loaded_quiz.FileName
        }
        1 { 
            $size = Read-Host "How long would you like the test to be?"
        }
        2 {
            $passing_score = Read-Host "Input new Passing Score"
        }
        3 {
            $change = Read-Host "Type 'ON' or 'OFF' to change."
            if ($change -eq "ON") {
                $feedback = $true
            }
            elseif ($change -eq "OFF") {
                $feedback = $false
            }
            else {
                Write-Host "Invalid Response: Type 'ON' or 'OFF' to alter Feedback Mode"
            }
        }
        4 {
            Show-Menu
            return
        }
        default {
            return
        }
    }
    $options.Clear()
    Show-SettingsMenu
}

function Save-QuizData {
    param (
        [PSCustomObject]$data
    )

    $yes = [ChoiceDescription]::new('&Yes', 'You would like this file saved for later use')
    $no = [ChoiceDescription]::new('&No', 'You would not like this file saved for later use')
    $options = [ChoiceDescription[]]($yes, $no)
    $choice = $host.UI.PromptForChoice("Would you like this file saved for easier use next time?","",$options,-1)

    switch($choice) {
        0 {
            $data_file = Get-Content -Raw .\data.json | ConvertFrom-Json
            [array] $data_file += $data
            $data_file | ConvertTo-Json | Out-File .\data.json
            return
        }
        default {
            return
        }
    }
}

function Show-QuizFile{
    param (
        [string]$name,
        [string]$file_name,
        [int32]$total_size
    )
    Write-Host "`n============= Quiz File Info =============" -ForegroundColor Yellow
    Write-Host "    Quiz Name   : $name" -ForegroundColor Cyan
    Write-Host "    File Path   : $file_name" -ForegroundColor Cyan
    Write-Host "    Total Size  : $total_size" -ForegroundColor Cyan
    Write-Host "====================================== ===`n" -ForegroundColor Yellow
}

function Set-QuizData {
    param (
        $data_file
    )
    $load = [ChoiceDescription]::new('&Load', 'Load Quiz info from data.json')
    $manual = [ChoiceDescription]::new('&Manual', 'Manually enter in Quiz Info')
    $back = [ChoiceDescription]::new('&Back', 'Return to previous menu')
    $options = [ChoiceDescription[]]($load, $manual, $back)
    $choice = $host.UI.PromptForChoice("Load from save file or input data manually?","",$options,-1)

    switch ($choice) {
        0 {
            ForEach ($file in $data_file) {
                Show-QuizFile -name $file.Name -file_name $file.FileName -total_size $file.TotalSize
            }

            $selection = Read-Host "Provide The Quiz Name you would like to load"
            $selection_quiz = $data_file | Where-Object {$_.Name -eq $selection}
            $name = $selection_quiz.Name
            $file_path = $selection_quiz.FileName
            $total_size = $selection_quiz.TotalSize
            Show-QuizFile -name $name -file_name $file_path -total_size $total_size
        }
        1 {
            
            $name = Read-Host "Input Quiz Name (A title or what you would like to call it)"
            $data_folder = Join-Path -Path $PSScriptRoot -ChildPath "quiz_data"
            do {
                $file_path = ((Read-Host "Input File Name (with extension)") -replace '"')
                $file_path_full = Join-Path -Path $data_folder -ChildPath $file_path
            } while (-not ((Test-Path $file_path_full -PathType Leaf) -and ($file_path -like "*.csv")))

            $total_size = (Import-Csv $file_path_full).Count

            Show-QuizFile -name $name -file_name $file_path -total_size $total_size
        }
        Default {
            return
        }
    }

    $yes = [ChoiceDescription]::new('&Yes', 'The Information is Accurate')
    $no = [ChoiceDescription]::new('&No', 'The Information is Inaccurate')
    $back = [ChoiceDescription]::new('&Back', 'Back to previous menu')
    $options = [ChoiceDescription[]]($yes, $no, $back)
    $choice = $host.UI.PromptForChoice("Is this correct?","",$options,-1)

    switch ($choice) {
        0 {
            $new_quiz = [PSCustomObject]@{
                Name = $name
                FileName = $file_path.Split('\')[-1]
                TotalSize = $total_size
            }
            if ($name -notin $data_file.Name){
                Save-QuizData -data $new_quiz
            }
            return $new_quiz
        }
        1{
            Set-QuizData
        }
        Default {
            return
        }
    }
}

function Show-Menu {
    param (
        [string]$Title = "Practice Test"
    )

    Show-Settings
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "• Run a new quiz" -ForegroundColor Cyan
    Write-Host "• Change Settings" -ForegroundColor Cyan
    Write-Host "• Exit the program" -ForegroundColor Cyan
    Write-Host "═════════════════════════════════════════" -ForegroundColor Yellow

    $run = [ChoiceDescription]::new('&Run','Run a quiz')
    $settings = [ChoiceDescription]::new('&Settings','Edit Settings')
    $exit = [ChoiceDescription]::new('E&XIT','Exit the Program')
    $options = [ChoiceDescription[]]($run,$settings,$exit)
    $choice = $host.UI.PromptForChoice("Select Option","",$options,-1)

    switch ($choice){
        0 {
            New-Quiz $quiz_file
        }
        1 {
            Show-SettingsMenu
        }
        2 {
            Write-Host "`nGoodbye  ¯\_(ツ)_/¯ "
            break
        }
    }
}


Show-Menu
