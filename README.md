# PowerQuiz
PowerShell-based Quiz script. 


## SYNOPSIS
PowerShell script for a Practice Test Taking Tool.

## DESCRIPTION
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

## INPUTS
None. You can't pipe objects to PowerQuiz.ps1

## OUTPUTS
Interactive Menu. Follow input directions.

## NOTES
File: QuizTool.ps1
Author: Shawn Wabschall
Last Update: October2023

## EXAMPLE
To start the quiz tool, run the script and follow the interactive menu prompts:
PS C:\> .\QuizTool.ps1

The menu provides options to run a quiz, display current settings, change settings, and exit the program.

## LINK
https://github.com/Wabbadabba/PowerQuiz




https://github.com/Wabbadabba/PowerQuiz/assets/11987489/c5d7c57b-eb75-4649-9a80-efbad71a4a61

