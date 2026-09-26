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
   import mmo.play.petfight.commonbuff.CommonBuff;
   import mmo.play.petfight.commonbuff.CommonBuffHelper;
   
   public class FIP_EffectComponent
   {
      
      private var _view:MovieClip = null;
      
      private var _effectObj:Object;
      
      private var _effectDesTxt:TextField;
      
      public function FIP_EffectComponent()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
      }
      
      public function refresh(param1:MovieClip, param2:Object) : void
      {
         var _loc6_:int = 0;
         this._view = param1;
         this._effectObj = param2;
         if(this._effectObj.hkBuff)
         {
            this._view.gotoAndStop(1);
         }
         else if(StatusUtil.isToteStatus(this._effectObj.st))
         {
            this._view.gotoAndStop(2);
         }
         else
         {
            this._view.gotoAndStop(3);
         }
         var _loc3_:MovieClip = this._view.getChildByName("mcStatusIcon") as MovieClip;
         DisplayUtil.clearChildren(_loc3_);
         var _loc4_:StatusIcon = FightMcPool.instance.getRes(StatusIcon,true);
         this._effectDesTxt = this._view.getChildByName("txtEffectDes") as TextField;
         if(this._effectDesTxt)
         {
            DisplayUtil.stopAndRemove(this._effectDesTxt);
         }
         var _loc5_:TextField = this._view.getChildByName("txtDes") as TextField;
         this._effectDesTxt = new TextField();
         this._effectDesTxt.name = "txtEffectDes";
         this._effectDesTxt.width = _loc5_.width;
         this._effectDesTxt.x = _loc5_.x;
         this._effectDesTxt.y = _loc5_.y;
         this._effectDesTxt.textColor = 7199487;
         this._effectDesTxt.wordWrap = true;
         this._effectDesTxt.selectable = false;
         if(this._effectObj.hkBuff)
         {
            _loc4_.startLoad(StatusIconHandler.StatusType_HK,1,0);
            ActComHelper.setTxtValue(this._view,"txtName",this._effectObj.hkBuff.name);
            this._effectDesTxt.htmlText = this._effectObj.hkBuff.desArr[0];
            this._effectDesTxt.setTextFormat(FIP_ResConfig.createTextFormat(13,2));
         }
         else
         {
            _loc6_ = StatusUtil.getFrame(this._effectObj.st);
            if(StatusUtil.isGQSkillWindWord(this._effectObj.st))
            {
               _loc4_.startLoad(StatusIconHandler.StatusType_CommonBuff,_loc6_,CommonBuffHelper.getResTurn(this._effectObj.st));
            }
            else if(this._effectObj.st.split("_").length < 5)
            {
               _loc4_.startLoad(StatusIconHandler.StatusType_Common,_loc6_,0);
            }
            else
            {
               _loc4_.startLoad(StatusIconHandler.StatusType_Common,_loc6_,Number(this._effectObj.st.split("_")[4]));
            }
            ActComHelper.setTxtValue(this._view,"txtName",StatusUtil.getTips(this._effectObj.st));
            this._effectDesTxt.htmlText = this.buffTipsHandle(StatusUtil.getDetailTips(this._effectObj.st));
            this._effectDesTxt.setTextFormat(FIP_ResConfig.createTextFormat(13,2));
         }
         this._effectDesTxt.height = this._effectDesTxt.textHeight + 5;
         this._view.addChild(this._effectDesTxt);
         _loc3_.addChild(_loc4_);
      }
      
      public function get viewHeight() : int
      {
         return this._effectDesTxt.height + 42.4;
      }
      
      public function addTips() : void
      {
         var _loc1_:MovieClip = this._view.getChildByName("mcStatusIcon") as MovieClip;
         TipsManager.getInstance().removeTips(_loc1_);
         if(this._effectObj.hkBuff)
         {
            TipsManager.getInstance().replaceComplexTips(_loc1_,this._effectObj.hkBuff.name,this._effectObj.hkBuff.desArr[0]);
         }
         else
         {
            TipsManager.getInstance().replaceComplexTips(_loc1_,StatusUtil.getTips(this._effectObj.st),StatusUtil.getDetailTips(this._effectObj.st));
         }
      }
      
      private function buffTipsHandle(param1:String) : String
      {
         var _loc4_:CommonBuff = null;
         var _loc2_:Array = CommonBuffHelper.getSkillTipsOther(param1);
         if(!_loc2_ || _loc2_.length == 0)
         {
            return param1;
         }
         param1 += "\n\n";
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            param1 += "<font color=\'#FFFF00\'>" + _loc4_.tips + ":" + "</font>";
            param1 += _loc4_.simpleTips + "\n";
            _loc3_++;
         }
         return param1.replace(/<br>/g,"\n");
      }
      
      public function dispose() : void
      {
      }
   }
}

