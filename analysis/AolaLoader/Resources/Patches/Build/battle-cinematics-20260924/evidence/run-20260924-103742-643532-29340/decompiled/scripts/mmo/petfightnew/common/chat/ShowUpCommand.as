package mmo.petfightnew.common.chat
{
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import mmo.common.DisplayUtil;
   import mmo.common.event.EnterFrameManager;
   import mmo.petfightnew.common.FightController;
   import mmo.play.flipscene.FlipSceneBase;
   import mmo.play.scene.SceneManager;
   import mmo.util.command.ISceneCommand;
   import mmo.util.command.SceneSimpleCommand;
   
   public class ShowUpCommand extends SceneSimpleCommand implements ISceneCommand
   {
      
      private static const BUBBLE_OFFSET:Point = new Point(0,-220);
      
      private var _content:Object;
      
      private var _layerPetUp:Sprite;
      
      public function ShowUpCommand()
      {
         super();
      }
      
      override public function execute(param1:Object) : void
      {
         var message:String;
         var petScale:Number;
         var txt:TextField;
         var initHeight:int;
         var addHeight:int;
         var point:Point;
         var container:Sprite = null;
         var player:Sprite = null;
         var border:Sprite = null;
         var adjust:Function = null;
         var content:Object = param1;
         adjust = function():void
         {
            var _loc1_:Point = null;
            EnterFrameManager.instance.remove(adjust);
            if(container && container.parent && Boolean(player.parent))
            {
               _loc1_ = container.parent.localToGlobal(new Point(container.x,container.y));
               if(_loc1_.y < 150 && _loc1_.x > 480)
               {
                  container.x -= 50;
                  container.y = 150;
               }
               if(_loc1_.y < border.height + 10)
               {
                  container.y += border.height + 10 - _loc1_.y;
               }
            }
         };
         this._content = content;
         container = content["container"] as Sprite;
         player = content["player"] as Sprite;
         message = content["message"] as String;
         petScale = Number(content["scale"]);
         txt = container.getChildByName("txtcontent") as TextField;
         initHeight = txt.height;
         txt.wordWrap = true;
         txt.autoSize = TextFieldAutoSize.CENTER;
         txt.selectable = false;
         txt.htmlText = message;
         addHeight = txt.height - initHeight;
         border = container.getChildByName("mcborder") as Sprite;
         border.height += addHeight;
         border.y -= addHeight;
         txt.y -= addHeight;
         container.x = BUBBLE_OFFSET.x * petScale;
         container.y = BUBBLE_OFFSET.y * petScale;
         if(SceneManager.getInstance().loadedSceneInfo.scene is FlipSceneBase)
         {
            txt.scaleY = -1;
            txt.y += txt.height;
         }
         this._layerPetUp = FightController.instance.fightPanel.layerPetUp;
         point = player.localToGlobal(new Point(container.x,container.y));
         this._layerPetUp.addChild(container);
         container.x = point.x;
         container.y = point.y;
         adjust();
         EnterFrameManager.instance.register(adjust,null,25);
         succeed(content);
         this._content = null;
      }
      
      override public function cancel() : void
      {
         var _loc1_:Sprite = this._content["container"] as Sprite;
         var _loc2_:Sprite = this._content["player"] as Sprite;
         if(this._layerPetUp.contains(_loc1_))
         {
            DisplayUtil.stopAndRemove(_loc1_);
         }
         this._content = null;
         super.cancel();
      }
   }
}

