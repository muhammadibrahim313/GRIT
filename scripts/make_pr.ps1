param([Parameter(Mandatory=$true)][string]$Day)
$branch = "dspy/day-$Day"
git checkout -b $branch
git add -A
git commit -m "DSPY Day $Day — update"
git push -u origin $branch
gh pr create --fill --title "DSPY Day $Day — update" --base main --head $branch
