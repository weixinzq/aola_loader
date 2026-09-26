package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetBattleEffDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.xinghui.XinghuiPetType;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol160")]
   public class TongLingSPTipsPanel extends MovieClip
   {
      
      public var btntonglingsp:SimpleButton;
      
      public var mcTips:MovieClip;
      
      private var btn:SimpleButton;
      
      private var tips:MovieClip;
      
      private const ONLY_POS:Point = new Point(0,0);
      
      private const DOUBLE_POS:Point = new Point(0,-60);
      
      private var ips:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var ieff:IPetBattleEffDataService = ServiceContainer.getService(IPetBattleEffDataService) as IPetBattleEffDataService;
      
      public function TongLingSPTipsPanel()
      {
         super();
         this.btn = this.btntonglingsp as SimpleButton;
         this.btn.addEventListener(MouseEvent.ROLL_OVER,this.onOverBtn);
         this.btn.addEventListener(MouseEvent.ROLL_OUT,this.onOutBtn);
         this.tips = this.mcTips as MovieClip;
         this.tips.visible = false;
      }
      
      public function refresh(param1:PetBriefInfo) : void
      {
         var _loc3_:Point = null;
         var _loc4_:String = null;
         var _loc5_:Boolean = false;
         var _loc6_:Array = null;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:MovieClip = null;
         var _loc11_:PMSkill = null;
         var _loc2_:PMData = this.ips.customData.pmDataMap.getPM(param1.raceId);
         this.visible = XinghuiPetType.isSpPet(_loc2_.getXinghuiType());
         if(this.visible)
         {
            _loc3_ = XinghuiPetType.isOnlySpPet(_loc2_.getXinghuiType()) ? this.ONLY_POS : this.DOUBLE_POS;
            this.btn.x = _loc3_.x;
            this.btn.y = _loc3_.y;
            _loc4_ = _loc2_.getXinghuiExtraConfig();
            _loc5_ = Boolean(XinghuiPetType.isEffUnlock(_loc4_));
            _loc6_ = XinghuiPetType.getSpExtraSkills(_loc4_);
            _loc7_ = int(XinghuiPetType.getUnlockEff(_loc4_));
            _loc6_ = this.sortSkill(_loc6_);
            _loc8_ = 0;
            while(_loc8_ < _loc6_.length)
            {
               _loc9_ = int(_loc6_[_loc8_]);
               _loc10_ = this.tips.getChildByName("mcskill_" + _loc8_) as MovieClip;
               _loc10_.visible = _loc9_ > 0;
               if(_loc10_.visible)
               {
                  _loc11_ = this.ips.customData.pmSkillMap.getSkill(_loc9_);
                  _loc10_.txtdecs.text = _loc11_.clientDesc;
                  _loc10_.txtpower.text = "威力:" + _loc11_.power;
                  _loc10_.txtname.text = _loc11_.newCnName;
                  _loc10_.mclock.gotoAndStop(_loc5_ ? 2 : 1);
                  _loc10_.mclock.visible = !this.ownLevel5Passive(param1,_loc5_,_loc7_);
               }
               _loc8_++;
            }
         }
      }
      
      private function ownLevel5Passive(param1:PetBriefInfo, param2:Boolean, param3:int) : Boolean
      {
         var _loc5_:SkillInfo = null;
         var _loc6_:PMSkill = null;
         if(param2)
         {
            return this.ieff.getPetBattleEffectiveness(param1) >= param3;
         }
         var _loc4_:Array = param1.skills;
         for each(_loc5_ in _loc4_)
         {
            _loc6_ = this.ips.customData.pmSkillMap.getSkill(_loc5_.id);
            if(_loc6_.getSkillType() == PMSkillTypes.XINGHUI_PASSIVE_SKILL)
            {
               if(_loc6_.getMaxLevelSkillId() == _loc6_.skillId)
               {
                  return true;
               }
            }
         }
         return false;
      }
      
      private function sortSkill(param1:Array) : Array
      {
         var _loc2_:Array = [];
         _loc2_.push(this.getTargetSkill(param1,PMSkillTypes.XINGHUI_KILL_BIG));
         _loc2_.push(this.getTargetSkill(param1,PMSkillTypes.XINGHUI_SUPER_SPIRIT_TEJI));
         _loc2_.push(this.getTargetSkill(param1,PMSkillTypes.XINGHUI_SP_PASSIVE_SKILL));
         return _loc2_;
      }
      
      private function getTargetSkill(param1:Array, param2:int) : int
      {
         var _loc3_:* = undefined;
         var _loc4_:int = 0;
         for each(_loc3_ in param1)
         {
            _loc4_ = parseInt(_loc3_);
            if(this.ips.customData.pmSkillMap.getSkill(_loc4_).getSkillType() == param2)
            {
               return _loc4_;
            }
         }
         return -1;
      }
      
      private function onOverBtn(param1:MouseEvent) : void
      {
         this.tips.visible = true;
      }
      
      private function onOutBtn(param1:MouseEvent) : void
      {
         this.tips.visible = false;
      }
   }
}

