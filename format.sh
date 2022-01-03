set -e
logos-format.py -assume-filename=Tweak.m <Tweak.x >Tweak.x.new
mv Tweak.x.new Tweak.x
