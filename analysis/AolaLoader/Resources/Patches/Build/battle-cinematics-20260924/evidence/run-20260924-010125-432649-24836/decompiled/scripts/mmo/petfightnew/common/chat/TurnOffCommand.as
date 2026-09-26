package mmo.petfightnew.common.chat
{
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.util.command.ISceneCommand;
   import mmo.util.command.SceneSimpleCommand;
   
   public class TurnOffCommand extends SceneSimpleCommand implements ISceneCommand
   {
      
      public function TurnOffCommand()
      {
         super();
      }
      
      override public function execute(param1:Object) : void
      {
         var _loc2_:Sprite = param1["container"] as Sprite;
         var _loc3_:Sprite = param1["player"] as Sprite;
         DisplayUtil.stopAndRemove(_loc2_);
         succeed(param1);
      }
      
      override public function cancel() : void
      {
         super.cancel();
      }
   }
}

