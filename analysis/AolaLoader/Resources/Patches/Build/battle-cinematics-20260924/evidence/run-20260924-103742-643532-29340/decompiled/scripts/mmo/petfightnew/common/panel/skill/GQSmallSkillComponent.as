package mmo.petfightnew.common.panel.skill
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.operation.IPMSkillInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.skill.ActPetAttrIcon;
   
   public class GQSmallSkillComponent
   {
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      private var _raceId:int;
      
      private var _view:MovieClip = null;
      
      private var _petInfo:PetBriefInfo = null;
      
      private var _pmService:IPMService;
      
      private var _petAttrIcon:ActPetAttrIcon;
      
      private var _pmSkill:PMSkill = null;
      
      public function GQSmallSkillComponent(param1:int, param2:MovieClip, param3:PetBriefInfo = null)
      {
         super();
         this._raceId = param1;
         this._view = param2;
         this._petInfo = param3;
         this.init();
      }
      
      private function init() : void
      {
         this._pmService = ServiceContainer.getService(IPMService) as IPMService;
         this._petAttrIcon = new ActPetAttrIcon(38);
      }
      
      public function refresh(param1:SkillInfo = null, param2:IPMSkillInfo = null) : void
      {
         var _loc3_:Sprite = null;
         var _loc4_:String = null;
         var _loc5_:MovieClip = null;
         if(param1 == null && param2 == null)
         {
            this._view.visible = false;
            return;
         }
         this._view.visible = true;
         if(param1 != null)
         {
            this._pmSkill = this._pmService.customData.pmSkillMap.getSkill(param1.id);
         }
         else
         {
            this._pmSkill = this._pmService.customData.pmSkillMap.getSkill(param2.skillId);
         }
         if(!PMSkillTypes.isGQKillBig(this._pmSkill.getSkillType()))
         {
            this._view.gotoAndStop(1);
            _loc3_ = this._view.getChildByName("mcAttHolder") as Sprite;
            if(_loc3_)
            {
               DisplayUtil.clearChildren(_loc3_);
               _loc3_.addChild(this._petAttrIcon.view);
            }
            if(PMSkillTypes.GQ_COMMON_PASSIVE != this._pmSkill.getSkillType())
            {
               this._petAttrIcon.refresh(this._pmSkill.attributeType);
            }
            Panel_Helper.setTextValue(this._view,"txtname",this._pmSkill.newCnName);
            _loc4_ = this._pmSkill.power < 0 ? "—" : this._pmSkill.power.toString();
            Panel_Helper.setTextValue(this._view,"txtpower",_loc4_);
            _loc5_ = this._view.getChildByName("mcPP") as MovieClip;
            if(PMSkillTypes.isGQCommonSpiritSkill(this._pmSkill.getSkillType()))
            {
               ActComHelper.setMcFrame(this._view,"mcSoul",this._pmSkill.costSoulNum);
               if(_loc5_)
               {
                  _loc5_.visible = false;
               }
            }
            else
            {
               ActComHelper.setVisible(this._view,"mcSoul",false);
               if(_loc5_)
               {
                  _loc5_.visible = true;
                  if(this._pmSkill.allPP <= 0)
                  {
                     ActComHelper.setMcNum(_loc5_,"mcUseNum",0);
                     ActComHelper.setMcNum(_loc5_,"mcAllNum",0);
                  }
                  else if(param1 != null)
                  {
                     ActComHelper.setMcNum(_loc5_,"mcUseNum",param1.canUseTimes);
                     ActComHelper.setMcNum(_loc5_,"mcAllNum",this._pmSkill.allPP);
                  }
                  else
                  {
                     ActComHelper.setMcNum(_loc5_,"mcUseNum",this._pmSkill.allPP);
                     ActComHelper.setMcNum(_loc5_,"mcAllNum",this._pmSkill.allPP);
                  }
               }
            }
         }
         else
         {
            this._view.gotoAndStop(2);
            ActComHelper.setMcFrame(this._view,"mcSoul",this._pmSkill.costSoulNum);
         }
         if(this._petInfo)
         {
            this.addSkillTips();
         }
      }
      
      private function addSkillTips() : void
      {
         var _loc2_:* = null;
         var _loc1_:int = int(this._petInfo.curGQSoulNum);
         if(this._gameOptionSvr.isGQSimpleSkillView)
         {
            _loc2_ = this._pmSkill.oldEffectDesc;
         }
         else
         {
            _loc2_ = this._pmSkill.clientDesc;
         }
         var _loc3_:SimpleButton = ActComHelper.getChildNode(this._view,"btnSkill") as SimpleButton;
         if(_loc1_ < this._pmSkill.costSoulNum && !StatusUtil.getIsinTouzhiCommonBuff(this._petInfo))
         {
            _loc2_ += "\n-------\n光能不足，不能使用该技能！";
            _loc3_.mouseEnabled = false;
         }
         else
         {
            _loc3_.mouseEnabled = true;
         }
         var _loc4_:String = this._pmSkill.newCnName + "\n威力：" + this.getSkillPowerDesc(this._pmSkill.power);
         TipsManager.getInstance().replaceComplexTips(this._view,_loc4_,_loc2_);
      }
      
      protected function getSkillPowerDesc(param1:int) : String
      {
         if(param1 > 0)
         {
            return param1.toString();
         }
         return "未知";
      }
      
      public function dispose() : void
      {
         this._petAttrIcon = null;
         this._pmSkill = null;
      }
   }
}

