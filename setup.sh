GITURL='https://github.com/optix2000/dotfiles.git'
DOTDIR='dotfiles'
DOTSUBDIR='dotfiles'
TMPDIR=`mktemp -d`
if [ -z "$TMPDIR" ]; then
    exit 1
fi
cd $TMPDIR
git clone --recursive $GITURL $DOTDIR
cd $DOTDIR
pwd
ls -l $DOTSUBDIR
shopt -s dotglob nullglob
mv -i $DOTSUBDIR/* ~/
mkdir -p ~/.vim/autoload ~/.vim/bundle
curl -LSso ~/.vim/autoload/pathogen.vim https://github.com/tpope/vim-pathogen/raw/master/autoload/pathogen.vim
rm -rf $TMPDIR
