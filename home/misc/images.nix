{ fetchurl
}:

{
  # https://www.reddit.com/r/wallpapers/comments/ge4hrd/geometry/
  login = fetchurl {
    url = "https://i.redd.it/tg9ac8kn10x41.jpg";
    sha256 = "0pb32hzrngl06c1icb2hmdq8ja7v1gc2m4ss32ihp6rk45c59lji";
  };

  # https://imgur.com/a/pYoXWtZ
  lock = fetchurl {
    url = "https://i.imgur.com/xXQ1B2K.png";
    sha256 = "1pj7rs5lfchy0m8kf174v3wqw13sv77a632297bjijm8hf2ps8g5";
  };
}
