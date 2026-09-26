package mmo.petfightnew.common.fightcontroller.fightinfopanel.common
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.operation.IPMSkillInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.skill.ActPetAttrIcon;
   import mmo.play.actthings.skill.tips.ActSkillTipsManager;
   
   public class FIP_SkillComponent
   {
      
      private var _view:MovieClip = null;
      
      private var _pmService:IPMService;
      
      private var _petAttrIcon:ActPetAttrIcon;
      
      private var _pmSkill:PMSkill = null;
      
      public function FIP_SkillComponent()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this._pmService = ServiceContainer.getService(IPMService) as IPMService;
         this._petAttrIcon = new ActPetAttrIcon(38);
      }
      
      public function refresh(param1:MovieClip, param2:SkillInfo = null, param3:IPMSkillInfo = null) : void
      {
         var _loc10_:int = 0;
         this._view = param1;
         var _loc4_:Sprite = this._view.getChildByName("attrcontainer") as Sprite;
         DisplayUtil.clearChildren(_loc4_);
         _loc4_.addChild(this._petAttrIcon.view);
         if(param2 == null && param3 == null)
         {
            this._view.visible = false;
            return;
         }
         this._view.visible = true;
         if(param2 != null)
         {
            this._pmSkill = this._pmService.customData.pmSkillMap.getSkill(param2.id);
         }
         else
         {
            _loc10_ = int(this._pmService.customData.pmSkillMap.getSkill(param3.skillId).getMaxLevelSkillId());
            this._pmSkill = this._pmService.customData.pmSkillMap.getSkill(_loc10_);
         }
         var _loc5_:int = int(this._pmSkill.getSkillType());
         ActComHelper.setMcFrame(this._view,"mcBg",PMSkillTypes.isGQPassiveSkill(_loc5_) ? 2 : 1);
         var _loc6_:MovieClip = ActComHelper.getChildNode(this._view,"mcSoul") as MovieClip;
         var _loc7_:MovieClip = ActComHelper.getChildNode(_loc6_,"mc0") as MovieClip;
         this._petAttrIcon.refresh(this._pmSkill.attributeType);
         Panel_Helper.setTextValue(this._view,"txtname",this._pmSkill.newCnName);
         var _loc8_:String = this._pmSkill.power < 0 ? "—" : this._pmSkill.power.toString();
         Panel_Helper.setTextValue(this._view,"mcPower.txtpower",_loc8_);
         var _loc9_:MovieClip = this._view.getChildByName("mcPP") as MovieClip;
         if(PMSkillTypes.isGQPassiveSkill(_loc5_))
         {
            Panel_Helper.setVisible(this._view,"txtname",false);
            Panel_Helper.setVisible(this._view,"mcSoul",false);
            Panel_Helper.setVisible(this._view,"mcPower",false);
            _loc9_.visible = false;
         }
         else if(this._pmSkill.costSoulNum > 0)
         {
            if(_loc7_)
            {
               ActComHelper.setMcAlignNumbers(_loc6_,"mc",this._pmSkill.costSoulNum);
            }
            else
            {
               ActComHelper.setMcFrame(this._view,"mcSoul",this._pmSkill.costSoulNum);
            }
            _loc9_.visible = false;
         }
         else
         {
            ActComHelper.setVisible(this._view,"mcSoul",false);
            _loc9_.visible = true;
            if(this._pmSkill.allPP <= 0)
            {
               ActComHelper.setMcNum(_loc9_,"mcUseNum",0);
               ActComHelper.setMcNum(_loc9_,"mcAllNum",0);
            }
            else if(param2 != null)
            {
               ActComHelper.setMcNum(_loc9_,"mcUseNum",param2.canUseTimes);
               ActComHelper.setMcNum(_loc9_,"mcAllNum",this._pmSkill.allPP);
            }
            else
            {
               ActComHelper.setMcNum(_loc9_,"mcUseNum",this._pmSkill.allPP);
               ActComHelper.setMcNum(_loc9_,"mcAllNum",this._pmSkill.allPP);
            }
         }
      }
      
      public function refreshSelect(param1:Boolean) : void
      {
         ActComHelper.setMcFrame(this._view,"mcBg.mcBg",param1 ? 2 : 1);
      }
      
      public function addTips(param1:SkillInfo) : void
      {
         ActSkillTipsManager.getInstance().removeTips(this._view.mcSkillTips);
         ActSkillTipsManager.getInstance().replaceTips(this._view.mcSkillTips,false,param1,null);
      }
      
      public function dispose() : void
      {
         this._petAttrIcon = null;
         this._pmSkill = null;
      }
   }
}

