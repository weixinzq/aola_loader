package mmo.petfightnew.common.chat
{
   import mmo.util.command.ISceneCommand;
   import mmo.util.command.SceneMacroCommand;
   
   public class SayingCommand extends SceneMacroCommand implements ISceneCommand
   {
      
      public function SayingCommand()
      {
         super();
      }
      
      override protected function initializeMacroCommand() : void
      {
         addSubCommand(DownloadCommand);
         addSubCommand(ShowUpCommand);
         addSubCommand(TimerCommand);
         addSubCommand(TurnOffCommand);
         super.initializeMacroCommand();
      }
   }
}

