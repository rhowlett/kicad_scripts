#!/usr/bin/env bash

os_type=$(uname)

# Check if it's macOS or Linux
if [ "$os_type" == "Darwin" ]; then
    echo "You are running macOS."
elif [ "$os_type" == "Linux" ]; then
    echo "You are running Linux."
else
    echo "Unsupported operating system: $os_type"
    help=true
fi

verbose=false
debug=false
cli_help=false
save_date=`date +%y%m%d%H%M%S`
tag="$USER - Update $save_date - $os_type:$HOSTNAME"

function CLI_HELP() 
{
	>&2 echo "TODO"
  echo -e "
USAGE:\n
$0 [options]\n
\n
OPTIONS:\n
-t | --tag <tag_name>  Default: $tag\n
-v | --verbose         Extra info\n
-d | --debug           Debug - will exit before push\n
-h | --help            This message\n
  "

	exit 1
}

# if you want long opts vs getops function this is a way to do it :)
CLI_ARGS=()
while [[ $# -gt 0 ]]
do
	case $1 in
		-t|--tag)
			tag=$2
			shift #moves to current value
			shift #moves to next arg
			;;
		-v|--verbose)
			verbose=true
			shift #moves to current value
			shift #moves to next arg
			;;
		-d|--debug)
			debug=true
			shift #moves to current value
			shift #moves to next arg
			;;
		-h|--help)
			cli_help=true
			shift #moves to current value
			shift #moves to next arg
			;;
		-*|--*)
			>&2 echo "-E- Unknown option $1, see the folloing help:"
			CLI_HELP
			exit 1
			;;
		*)
			CLI_ARGS+=("$1")
			shift #moves to current value
			;;
	esac
done

if $cli_help
then
	CLI_HELP
fi

if $verbose ; then echo "-W- Pull all files from git repo";fi
git pull

# Reseting all file from the commit
if $verbose ; then echo "-W- Reseting all files from prior git commit";fi
git reset *

# Test that files are not toooo big <100MB
max_size=104857600  # 100MB in bytes

# get a list of files that have changed from the main branch
#diff_files=$(git diff --name-only )
diff_files=$(git status -s -u )
if [[ -f /tmp/remove_big_files.txt ]]
then
  rm  /tmp/remove_big_files.txt
fi

touch /tmp/remove_big_files.txt

found_big_file=false
# check if those files are > 100MB
# Format of diff_files:
#[M|D|??] <file>
# Where:
#   M = Modified
#   D = Deleted
#  ?? = New / Unknown

for file in $diff_files; do
    if [[ -f "$file" ]]; then

        size=0
        if [ "$os_type" == "Darwin" ]; then
          size=$(stat -f "%z" "$file")
        else
          size=$(stat -c%s "$file")
        fi

        if [ $size -gt $max_size ]; then
            echo "-W- Wanring ❌ $file exceeds 100MB (actual size: $size bytes)."
            echo "git reset $file" >>/tmp/remove_big_files.txt
            found_big_file=true
        fi
    fi
done

if $verbose ; then echo "-W- Adding all files to git commit";fi
git add *

if $found_big_file
then
  if $verbose ; then echo "-W- Removing files from the commit that are >100MB" ; fi
  if $debug ; then cat /tmp/remove_big_files.txt ; fi
  . /tmp/remove_big_files.txt
  rm /tmp/remove_big_files.txt
  if $verbose ; then echo "-W- New Status" ; fi
fi

git status

if $verbose ; then echo "-W- Creating git commit with the following tag '$tag'" ; fi
git commit -m "$tag"

if $debug
then
  echo "-D- Exiting before the push"
else
  if $verbose ; then echo "-W- Pushing.." ; fi
  git push
fi
echo "-W- DONE"
