cd ~
if [ -d Strata-fork/.git ]; then
    git -C Strata-fork pull --ff-only
else
    git clone git@github.com:dorigoa/Strata-fork.git
fi

cd Strata-fork
./custom-start.sh