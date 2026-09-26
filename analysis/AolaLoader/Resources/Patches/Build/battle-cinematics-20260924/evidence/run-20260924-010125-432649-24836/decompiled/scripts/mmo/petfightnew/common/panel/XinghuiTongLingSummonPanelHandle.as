package mmo.petfightnew.common.panel
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.data.XHTongLingSkillParse;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   import mmo.petfightnew.common.fightcontroller.UseBigSkillHandler;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.play.actthings.helper.ActComHelper;
   
   public class XinghuiTongLingSummonPanelHandle
   {
      
      private var _pbi:PetBriefInfo = null;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _pmData:PMData;
      
      private var _pskSvr:IPetSkillMesService = null;
      
      private var _skillList:Array = [];
      
      private var _skillParse:XHTongLingSkillParse;
      
      private var _changeViewBtnEnabled:Boolean = true;
      
      private var _content:MovieClip;
      
      private var _cd:int = -1;
      
      private var _mcSkillList:MovieClip;
      
      private var _isDisplaySkill:Boolean = false;
      
      public function XinghuiTongLingSummonPanelHandle()
      {
         super();
      }
      
      public function dispose() : void
      {
         this.removeListener();
      }
      
      private function removeListener() : void
      {
         if(this._content)
         {
            this._content.removeEventListener(MouseEvent.ROLL_OVER,this.onRollOverHandle);
            this._content.removeEventListener(MouseEvent.ROLL_OUT,this.onRollOutHandle);
            this._content.removeEventListener(MouseEvent.CLICK,this.onClick);
         }
      }
      
      private function addListener() : void
      {
         this.removeListener();
         if(this._content)
         {
            this._content.addEventListener(MouseEvent.CLICK,this.onClick);
            this._content.addEventListener(MouseEvent.ROLL_OVER,this.onRollOverHandle);
            this._content.addEventListener(MouseEvent.ROLL_OUT,this.onRollOutHandle);
         }
      }
      
      private function initSkillList() : void
      {
         var _loc3_:SkillInfo = null;
         var _loc4_:int = 0;
         if(this._skillList)
         {
            this._skillList.length = 0;
         }
         else
         {
            this._skillList = new Array();
         }
         var _loc1_:Array = this._pbi.skills.concat();
         var _loc2_:int = int(_loc1_.length - 1);
         while(_loc2_ >= 0)
         {
            _loc3_ = _loc1_[_loc2_];
            _loc4_ = int(this._pmSvr.customData.pmSkillMap.getSkill(_loc3_.id).getSkillType());
            if(_loc4_ == PMSkillTypes.TONG_LING_ACTIVE)
            {
               this._skillList.push(_loc3_.id);
            }
            _loc2_--;
         }
      }
      
      public function refresh(param1:PetBriefInfo, param2:MovieClip) : void
      {
         this._pbi = param1;
         this._content = param2;
         this._pmData = this._pmSvr.getOperationPM(this._pbi.raceId).pmData;
         if(XinghuiPetType.isTongLing(this._pmData.getXinghuiType()) == false)
         {
            this._content.visible = false;
            this.dispose();
            return;
         }
         this._content.visible = true;
         var _loc3_:MovieClip = this._content.getChildByName("mcType") as MovieClip;
         var _loc4_:Object = XinghuiPetType.getTongLingObject(this._pbi.raceId);
         if(!_loc4_)
         {
            _loc3_.gotoAndStop(1);
         }
         else
         {
            _loc3_.gotoAndStop(_loc4_.summonSkillFrame);
         }
         this._mcSkillList = this._content.getChildByName("mcSkillList") as MovieClip;
         this._mcSkillList.visible = this._isDisplaySkill;
         this._changeViewBtnEnabled = true;
         this._skillParse = XHTongLingSkillParse.getTongLingSkillData(this._pbi.raceId);
         this._pskSvr = ServicePool.instance.getService(IPetSkillMesService);
         this.initSkillList();
         this._cd = this.getCd(this._pbi.status);
         if(this._cd == 0)
         {
            TipsManager.getInstance().removeTips(_loc3_);
            DisplayUtil.clearFilters(_loc3_);
         }
         else
         {
            TipsManager.getInstance().addTips(_loc3_,this._cd + "回合后方可使用该技能");
            DisplayUtil.applyGray(_loc3_);
         }
         this.setSkillMc();
         this.addListener();
      }
      
      private function setSkillMc() : void
      {
         var constAry:Array;
         var maxLen:int;
         var i:int;
         var updateSingleLiBaoState:Function = null;
         var useSkillId:int = 0;
         var skillMc:MovieClip = null;
         var pmSkill:PMSkill = null;
         var tipsTitle:String = null;
         updateSingleLiBaoState = function(param1:DisplayObject, param2:int):void
         {
            param1.visible = false;
         };
         ActComHelper.foreachCallback(this._mcSkillList,"mcskill_",updateSingleLiBaoState);
         constAry = this._skillParse.summonSkillAry.concat();
         maxLen = int(constAry.length);
         i = 0;
         while(i < maxLen)
         {
            useSkillId = int(constAry[i]);
            skillMc = this._mcSkillList.getChildByName("mcskill_" + i) as MovieClip;
            if(skillMc != null)
            {
               skillMc.visible = true;
               if(this._skillList.indexOf(useSkillId) == -1)
               {
                  skillMc.gotoAndStop(3);
               }
               else if(this._cd > 0 || !this._changeViewBtnEnabled)
               {
                  skillMc.gotoAndStop(2);
               }
               else
               {
                  skillMc.gotoAndStop(1);
               }
               pmSkill = this._pmSvr.customData.pmSkillMap.getSkill(useSkillId);
               (skillMc.txtName as TextField).text = pmSkill.newCnName;
               tipsTitle = pmSkill.newCnName + " 威力：" + this.getSkillPowerDesc(pmSkill.power);
               TipsManager.getInstance().replaceComplexTips(skillMc,tipsTitle,pmSkill.clientDesc,100,-100,9);
            }
            i++;
         }
      }
      
      private function getCd(param1:String) : int
      {
         var _loc4_:String = null;
         var _loc5_:Array = null;
         if(param1 == null || param1 == "")
         {
            return 0;
         }
         var _loc2_:Array = param1.split(",");
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = _loc2_[_loc3_];
            _loc5_ = _loc4_.split("_");
            if(_loc5_[0] == "psyc")
            {
               return parseInt(_loc5_[1]);
            }
            _loc3_++;
         }
         return 0;
      }
      
      private function getSkillPowerDesc(param1:int) : String
      {
         if(param1 > 0)
         {
            return param1.toString();
         }
         return "未知";
      }
      
      public function setClickable(param1:Boolean) : void
      {
         this._changeViewBtnEnabled = param1;
         this.setSkillMc();
      }
      
      private function onRollOverHandle(param1:MouseEvent) : void
      {
         this._isDisplaySkill = true;
         if(this._mcSkillList)
         {
            this._mcSkillList.visible = true;
         }
      }
      
      private function onRollOutHandle(param1:MouseEvent) : void
      {
         this._isDisplaySkill = false;
         if(this._mcSkillList)
         {
            this._mcSkillList.visible = false;
         }
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:PMSkill = null;
         var _loc5_:int = 0;
         if(!this._changeViewBtnEnabled)
         {
            return;
         }
         if(param1.target.name == "btnTongLingSkill")
         {
            _loc2_ = parseInt(param1.target.parent.name.split("_")[1]);
            _loc3_ = int(this._skillParse.summonSkillAry[_loc2_]);
            _loc4_ = this._pmSvr.customData.pmSkillMap.getSkill(_loc3_);
            _loc5_ = int(_loc4_.getSkillType());
            if(UseBigSkillHandler.instance.isHandling() && !UseBigSkillHandler.instance.isUsingSkill(_loc5_,_loc3_))
            {
               UseBigSkillHandler.instance.cancelUse();
            }
            UseBigSkillHandler.instance.handleUse(this._pbi,_loc3_,_loc5_);
            this.setClickable(false);
         }
      }
   }
}

