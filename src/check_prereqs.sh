die () {
  echo $*
  exit 1
}

test -f /usr/local/bin/hub || die "Please install hub from https://hub.github.com/"

test -f /usr/local/bin/things.sh || die "Please install things.sh from https://github.com/AlexanderWillner/things.sh"

[ -z "$CURRENT_GITHUB_USER" ] && die "Please define the CURRENT_GITHUB_USER environment variable"

[ -z "$THINGS_AUTH_TOKEN" ] && die "Please define the THINGS_AUTH_TOKEN environment variable"
