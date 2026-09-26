package mmo.petfightnew.common.fightcontroller.fightinfopanel.common
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.summoner.skill.SummonerSkillDataConfig;
   import mmo.interfaces.summoner.skill.SummonerSkillInfo;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.config.FIP_ResConfig;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.panel.status.StatusIcon;
   import mmo.petfightnew.common.panel.status.StatusIconHandler;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.petfight.common.config.StampConfig;
   import mmo.play.petfight.commonbuff.CommonBuffHelper;
   
   public class FIP_YinJiComponent
   {
      
      private var _view:MovieClip = null;
      
      private var _st:String;
      
      private var _yinjiDesTxt:TextField;
      
      public function FIP_YinJiComponent()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
      }
      
      public function refresh(param1:MovieClip, param2:String) : void
      {
         var _loc6_:Array = null;
         var _loc7_:StatusIcon = null;
         var _loc8_:int = 0;
         this._view = param1;
         this._st = param2;
         var _loc3_:SummonerSkillInfo = null;
         if(StampConfig.checkIsStampStatus(this._st))
         {
            this._view.gotoAndStop(1);
         }
         else if(StatusUtil.isZhaoHuanShiStatus(this._st))
         {
            this._view.gotoAndStop(2);
            _loc6_ = this._st.split("_")[1].split(":");
            _loc3_ = SummonerSkillDataConfig.getSkillInfo(parseInt(_loc6_[0]),parseInt(_loc6_[1]));
         }
         else if(StatusUtil.isGQTujian(this._st))
         {
            this._view.gotoAndStop(3);
         }
         var _loc4_:MovieClip = this._view.getChildByName("mcStatusIcon") as MovieClip;
         DisplayUtil.clearChildren(_loc4_);
         this._yinjiDesTxt = this._view.getChildByName("txtYinjiDes") as TextField;
         if(this._yinjiDesTxt)
         {
            DisplayUtil.stopAndRemove(this._yinjiDesTxt);
         }
         var _loc5_:TextField = this._view.getChildByName("txtDes") as TextField;
         this._yinjiDesTxt = new TextField();
         this._yinjiDesTxt.name = "txtYinjiDes";
         this._yinjiDesTxt.width = _loc5_.width;
         this._yinjiDesTxt.x = _loc5_.x;
         this._yinjiDesTxt.y = _loc5_.y;
         this._yinjiDesTxt.textColor = 7199487;
         this._yinjiDesTxt.wordWrap = true;
         this._yinjiDesTxt.selectable = false;
         if(!StatusUtil.isZhaoHuanShiStatus(this._st))
         {
            _loc7_ = FightMcPool.instance.getRes(StatusIcon,true);
            _loc8_ = StatusUtil.getFrame(this._st);
            if(StatusUtil.isGQSkillWindWord(this._st))
            {
               _loc7_.startLoad(StatusIconHandler.StatusType_CommonBuff,_loc8_,CommonBuffHelper.getResTurn(this._st));
            }
            else if(this._st.split("_").length < 5)
            {
               _loc7_.startLoad(StatusIconHandler.StatusType_Common,_loc8_,0);
            }
            else
            {
               _loc7_.startLoad(StatusIconHandler.StatusType_Common,_loc8_,Number(this._st.split("_")[4]));
            }
            _loc7_.mouseEnabled = _loc7_.mouseChildren = false;
            _loc4_.addChild(_loc7_);
            ActComHelper.setTxtValue(this._view,"txtName",StatusUtil.getTips(this._st));
            ActComHelper.setVisible(this._view,"mcSummonerIcon",false);
            this._yinjiDesTxt.htmlText = StatusUtil.getDetailTips(this._st);
         }
         else
         {
            ActComHelper.setVisible(this._view,"mcSummonerIcon",true);
            ActComHelper.setMcFrame(this._view,"mcSummonerIcon",_loc3_.skillId + 1);
            ActComHelper.setMcEnable(this._view,"mcSummonerIcon",false);
            ActComHelper.setTxtValue(this._view,"txtName",_loc3_.skillName);
            this._yinjiDesTxt.htmlText = _loc3_.skillDesc;
         }
         this._yinjiDesTxt.setTextFormat(FIP_ResConfig.createTextFormat(13,2));
         this._yinjiDesTxt.height = this._yinjiDesTxt.textHeight + 5;
         this._view.addChild(this._yinjiDesTxt);
      }
      
      public function get viewHeight() : int
      {
         return this._yinjiDesTxt.height + 42.4;
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

