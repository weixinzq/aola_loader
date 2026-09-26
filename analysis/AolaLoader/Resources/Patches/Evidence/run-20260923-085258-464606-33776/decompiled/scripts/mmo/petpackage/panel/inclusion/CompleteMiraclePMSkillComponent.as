package mmo.petpackage.panel.inclusion
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1260")]
   public class CompleteMiraclePMSkillComponent extends Sprite
   {
      
      public var attrcontainer:MovieClip;
      
      public var passiveskill:MovieClip;
      
      public var txtname:TextField;
      
      public var txtpower:TextField;
      
      public var txtpp:TextField;
      
      private var _pmService:IPMService;
      
      private var _petAttrIcon:PetAttrIcon;
      
      private var _seriesIndex:int;
      
      private var _skillInfo:SkillInfo;
      
      private var _miraclePetId:int;
      
      private var _skillIndex:int;
      
      public function CompleteMiraclePMSkillComponent()
      {
         super();
         this._pmService = ServiceContainer.getService(IPMService) as IPMService;
         this.init();
      }
      
      private function init() : void
      {
         this._petAttrIcon = new PetAttrIcon();
         var _loc1_:Sprite = this.getChildByName("attrcontainer") as Sprite;
         _loc1_.addChild(this._petAttrIcon.view);
      }
      
      public function refresh(param1:int, param2:SkillInfo, param3:Boolean = false) : *
      {
         if(param2 == null)
         {
            return;
         }
         this._skillIndex = param1;
         this._skillInfo = param2;
         var _loc4_:int = int(this._pmService.customData.pmSkillMap.getSkill(param2.id).attributeType);
         this._petAttrIcon.refresh(_loc4_);
         var _loc5_:PMSkill = this._pmService.customData.pmSkillMap.getSkill(param2.id);
         this.txtname.text = _loc5_.newCnName;
         this.txtpower.text = _loc5_.power < 0 ? "—" : _loc5_.power.toString();
         if(_loc5_.allPP == 0)
         {
            this.txtpp.text = "--/--";
         }
         else
         {
            this.txtpp.text = param2.canUseTimes + "/" + _loc5_.allPP;
         }
         DisplayObject(this["passiveskill"]).visible = param3;
         var _loc6_:String = _loc5_.newCnName + this.getSkillType(_loc5_.attackType);
         TipsManager.getInstance().replaceComplexTips(this,_loc6_,_loc5_.clientDesc,0,9,-50);
      }
      
      private function getSkillType(param1:int) : String
      {
         switch(param1)
         {
            case 0:
               return "(普通攻击)";
            case 1:
               return "(特殊攻击)";
            case 2:
               return "(属性攻击)";
            default:
               return "";
         }
      }
      
      public function dispose() : void
      {
      }
   }
}

