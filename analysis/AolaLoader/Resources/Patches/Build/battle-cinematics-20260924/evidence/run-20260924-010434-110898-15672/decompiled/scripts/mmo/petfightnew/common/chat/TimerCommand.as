package mmo.petfightnew.common.chat
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.petfightnew.common.manager.FightEnterFrameManager;
   import mmo.petfightnew.common.manager.FightFrameListener;
   import mmo.util.command.ISceneCommand;
   import mmo.util.command.SceneSimpleCommand;
   
   public class TimerCommand extends SceneSimpleCommand implements ISceneCommand
   {
      
      private var _frameListener:FightFrameListener = null;
      
      private var _content:Object;
      
      public function TimerCommand()
      {
         super();
      }
      
      override public function execute(param1:Object) : void
      {
         var _loc2_:int = 0;
         this._content = param1;
         var _loc3_:String = param1["message"] as String;
         if(_loc3_ == null)
         {
            _loc2_ = 4 * 25;
         }
         else if(int(param1["second"]) <= 0)
         {
            _loc2_ = _loc3_.length * 2.5;
            _loc2_ = Math.max(_loc2_,3 * 25);
            _loc2_ = Math.min(_loc2_,10 * 25);
         }
         else
         {
            _loc2_ = int(param1["second"]) * 25;
         }
         this._frameListener = new FightFrameListener(this.onCompleted,_loc2_,1);
         FightEnterFrameManager.instance.addFrameListener(this._frameListener);
      }
      
      override public function cancel() : void
      {
         FightEnterFrameManager.instance.removeFrameListener(this._frameListener);
         var _loc1_:Sprite = this._content["container"] as Sprite;
         var _loc2_:Sprite = this._content["player"] as Sprite;
         DisplayUtil.stopAndRemove(_loc1_);
         this._content = null;
      }
      
      private function disposeFrameListener() : void
      {
         this._frameListener.dispose();
         FightEnterFrameManager.instance.addFrameListener(this._frameListener);
         this._frameListener = null;
      }
      
      private function onCompleted() : void
      {
         this.disposeFrameListener();
         var _loc1_:MovieClip = this._content["face"] as MovieClip;
         if(_loc1_ != null)
         {
            DisplayUtil.stopAndRemove(_loc1_);
         }
         succeed(this._content);
         this._content = null;
      }
   }
}

