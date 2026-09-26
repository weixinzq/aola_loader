package mmo.petfightnew.common.fightcontroller.fightinfopanel.common
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.config.FIP_ResConfig;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.panel.status.StatusIcon;
   import mmo.petfightnew.common.panel.status.StatusIconHandler;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.petfight.commonbuff.CommonBuffHelper;
   
   public class FIP_StatusComponent
   {
      
      private var _view:MovieClip = null;
      
      private var _st:String;
      
      private var _statusDesTxt:TextField;
      
      public function FIP_StatusComponent()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
      }
      
      public function refresh(param1:MovieClip, param2:String) : void
      {
         this._view = param1;
         this._st = param2;
         var _loc3_:MovieClip = this._view.getChildByName("mcStatusIcon") as MovieClip;
         DisplayUtil.clearChildren(_loc3_);
         var _loc4_:int = StatusUtil.getFrame(this._st);
         var _loc5_:StatusIcon = FightMcPool.instance.getRes(StatusIcon,true);
         if(StatusUtil.isGQSkillWindWord(this._st))
         {
            _loc5_.startLoad(StatusIconHandler.StatusType_CommonBuff,_loc4_,CommonBuffHelper.getResTurn(this._st));
         }
         else if(this._st.split("_").length < 5)
         {
            _loc5_.startLoad(StatusIconHandler.StatusType_Common,_loc4_,0);
         }
         else
         {
            _loc5_.startLoad(StatusIconHandler.StatusType_Common,_loc4_,Number(param2.split("_")[4]));
         }
         _loc3_.addChild(_loc5_);
         ActComHelper.setTxtValue(this._view,"txtName",StatusUtil.getTips(this._st));
         this._statusDesTxt = this._view.getChildByName("txtStatusDes") as TextField;
         if(this._statusDesTxt)
         {
            DisplayUtil.stopAndRemove(this._statusDesTxt);
         }
         var _loc6_:TextField = this._view.getChildByName("txtDes") as TextField;
         this._statusDesTxt = new TextField();
         this._statusDesTxt.name = "txtStatusDes";
         this._statusDesTxt.width = _loc6_.width;
         this._statusDesTxt.x = _loc6_.x;
         this._statusDesTxt.y = _loc6_.y;
         this._statusDesTxt.textColor = 7199487;
         this._statusDesTxt.wordWrap = true;
         this._statusDesTxt.selectable = false;
         this._statusDesTxt.htmlText = StatusUtil.getDetailTips(this._st);
         this._statusDesTxt.setTextFormat(FIP_ResConfig.createTextFormat(13,2));
         this._statusDesTxt.height = this._statusDesTxt.textHeight + 5;
         this._view.addChild(this._statusDesTxt);
      }
      
      public function get viewHeight() : int
      {
         return this._statusDesTxt.height + 20.75;
      }
      
      public function addTips() : void
      {
         var _loc1_:MovieClip = this._view.getChildByName("mcStatusIcon") as MovieClip;
         TipsManager.getInstance().removeTips(_loc1_);
         TipsManager.getInstance().replaceComplexTips(_loc1_,StatusUtil.getTips(this._st),StatusUtil.getDetailTips(this._st));
      }
      
      public function dispose() : void
      {
      }
   }
}

