package mmo.petfightnew.common.panel.status
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.util.StatusUtil;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2307")]
   public class StatusItem extends Sprite implements IDispose
   {
      
      public var txtStatusDes:TextField;
      
      private var _icon:StatusIcon = null;
      
      private var _status:String;
      
      public function StatusItem()
      {
         super();
      }
      
      public function init(param1:String) : void
      {
         this._status = param1;
         var _loc2_:int = StatusUtil.getFrame(this._status);
         if(this._icon == null)
         {
            this._icon = FightMcPool.instance.getRes(StatusIcon,true);
         }
         this.addChild(this._icon);
         var _loc3_:TextField = this.getChildByName("txtStatusDes") as TextField;
         _loc3_.text = StatusUtil.getTips(this._status);
         this._icon.gotoAndStop(_loc2_);
      }
      
      public function addTips() : void
      {
         TipsManager.getInstance().removeTips(this._icon);
         TipsManager.getInstance().replaceComplexTips(this._icon,StatusUtil.getTips(this._status),StatusUtil.getDetailTips(this._status));
      }
      
      public function dispose() : void
      {
         FightMcPool.instance.recycle(this._icon);
      }
   }
}

