{ ... }:

{
  # Load the real file:
  imports = [ ./home ];

  # Make this machine an X server:
  pjones = {
    enable = true;
    xsession.enable = true;
  };
}
