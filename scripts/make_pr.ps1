param([Parameter(Mandatory=$true)][string]$Day)
$branch = "grit/day-$Day"
git checkout -b $branch
git add -A
git commit -m "GRIT Day $Day — update"
git push -u origin $branch
gh pr create --fill --title "GRIT Day $Day — update" --base main --head $branch
