{ inputs, ... }:
{
  imports = [
    inputs.maccel.nixosModules.default
  ];

  hardware.maccel = {
    enable = true;
    enableCli = true; # Optional

    parameters = {
      # Common (all modes)
      sensMultiplier = 1.0;
      yxRatio = 1.0;
      inputDpi = 1000.0;
      angleRotation = 0.0;
      mode = "linear";

      # Linear mode
      acceleration = 0.3;
      offset = 2.0;
      outputCap = 2.0;

      # # Natural mode
      # decayRate = 0.1;
      # offset = 2.0;
      # limit = 1.5;

      # # Synchronous mode
      # gamma = 1.0;
      # smooth = 0.5;
      # motivity = 2.5;
      # syncSpeed = 10.0;
    };
  };

  # To use maccel CLI/TUI without sudo
  users.groups.maccel.members = [ "stschiff" ];
}
