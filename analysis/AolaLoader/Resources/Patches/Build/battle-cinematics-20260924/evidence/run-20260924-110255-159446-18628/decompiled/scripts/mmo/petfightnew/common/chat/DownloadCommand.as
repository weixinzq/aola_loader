package mmo.petfightnew.common.chat
{
   import flash.display.DisplayObject;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.util.command.ISceneCommand;
   import mmo.util.command.SceneSimpleCommand;
   
   public class DownloadCommand extends SceneSimpleCommand implements ISceneCommand
   {
      
      private var _content:Object;
      
      public function DownloadCommand()
      {
         super();
      }
      
      override public function execute(param1:Object) : void
      {
         this._content = param1;
         var _loc2_:String = param1["url"] as String;
         var _loc3_:String = param1["className"] as String;
         ResScheduler.getResource(_loc2_,this.onGetContainer,_loc3_);
      }
      
      override public function cancel() : void
      {
         this._content = null;
         ResScheduler.cancel("play_res",this.onGetContainer);
         super.cancel();
      }
      
      private function onGetContainer(param1:DisplayObject) : void
      {
         if(this._content == null)
         {
            return;
         }
         this._content["container"] = param1;
         succeed(this._content);
         this._content = null;
      }
   }
}

