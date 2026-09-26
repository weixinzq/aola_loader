package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.petcorps.IPetCorpsService;
   import mmo.interfaces.petcorps.PetCorpsSkill;
   import mmo.interfaces.petcorps.PetCorpsSkillType;
   import mmo.play.activity.activitylimiter.ActivityId;
   import mmo.play.activity.activitylimiter.ActivityLimiter;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2569")]
   public class PetCorpsIcon extends MovieClip
   {
      
      public var btnPetCorps:SimpleButton;
      
      private const ABILITYS:Array = ["体力","攻击","防御","特攻","特防","速度"];
      
      private const ABILITY_INDEX_MAP:Array = [1,3,2,4,0,5];
      
      private const SKILL_ORDER:Array = [PetCorpsSkillType.ATTACK,PetCorpsSkillType.DEFENCE];
      
      private const SKILL_TYPE_DESC:Array = ["攻","防"];
      
      private const SKILL_OFF_SETS:Array = [new Point(-50,-180),new Point(-50,-220),new Point(-50,-270)];
      
      private const PET_CORPS_SERVICE:IPetCorpsService = ServiceContainer.getService(IPetCorpsService) as IPetCorpsService;
      
      private const PET_DATA_SERVICE:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
      
      public function PetCorpsIcon()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this.addEventListener(MouseEvent.CLICK,this.onClickPetCorps);
         this.PET_DATA_SERVICE.addEventListener(PetDataServiceEvent.ON_HIGHTES_BATTLE_EFF_UPDATE,this.onHighestBEUpdated);
         this.refreshIconView();
      }
      
      private function onHighestBEUpdated(param1:PetDataServiceEvent) : void
      {
         this.refreshIconView();
      }
      
      private function refreshIconView() : void
      {
         var _loc1_:Point = null;
         var _loc2_:int = 0;
         if(ActivityLimiter.checkIsOpen(ActivityId.PET_CORPS))
         {
            this.mouseChildren = true;
            DisplayUtil.clearFilters(this);
            _loc1_ = this.getTipsOffset();
            TipsManager.getInstance().replaceComplexTips(this,this.getIconTipsTitle(),this.getIconTipsContenet(),0,_loc1_.x,_loc1_.y);
         }
         else
         {
            this.mouseChildren = false;
            DisplayUtil.applyGray(this);
            _loc2_ = int(ActivityLimiter.getActivityOpenBe(ActivityId.PET_CORPS));
            TipsManager.getInstance().replaceTips(this,"战斗力到达" + _loc2_ + "才推荐开启这个功能哦！");
         }
      }
      
      private function onClickPetCorps(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnPetCorps")
         {
            this.showPetCorpsMainPanel();
         }
      }
      
      private function showPetCorpsMainPanel() : void
      {
         ModalDialogManager.getInstance().clearAll();
         this.PET_CORPS_SERVICE.showPetCorpsMainPanel();
      }
      
      private function getIconTipsTitle() : String
      {
         return "亚比军团";
      }
      
      private function getIconTipsContenet() : String
      {
         return "全背包战力提升:" + this.PET_CORPS_SERVICE.getPetCorpsOfferedBattleEff() + "\n" + "全背包属性提升:\n" + this.getAbilityDesc();
      }
      
      private function getAbilityDesc() : String
      {
         var _loc1_:Array = this.PET_CORPS_SERVICE.getTotalAddAbilitys();
         var _loc2_:String = "";
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < this.ABILITYS.length)
         {
            _loc3_ = int(this.ABILITY_INDEX_MAP[_loc4_]);
            _loc2_ += this.ABILITYS[_loc3_] + ":" + _loc1_[_loc3_] + "\n";
            _loc4_++;
         }
         return _loc2_;
      }
      
      private function getSkillDesc() : String
      {
         var _loc1_:* = "激活军团技能：\n";
         var _loc2_:Array = this.PET_CORPS_SERVICE.getCurSelectedSkills();
         var _loc3_:PetCorpsSkill = null;
         var _loc4_:int = 0;
         while(_loc4_ < this.SKILL_ORDER.length)
         {
            _loc1_ += this.SKILL_TYPE_DESC[_loc4_] + ":";
            _loc3_ = this.getSkill(_loc4_);
            if(_loc3_)
            {
               _loc1_ += _loc3_.skillName + "Lv" + _loc3_.skillLevel + " " + _loc3_.skillDesc;
            }
            else
            {
               _loc1_ += "未激活";
            }
            if(_loc4_ != this.SKILL_ORDER.length - 1)
            {
               _loc1_ += "\n";
            }
            _loc4_++;
         }
         return _loc1_;
      }
      
      private function getSkill(param1:int) : PetCorpsSkill
      {
         var _loc2_:Array = this.PET_CORPS_SERVICE.getCurSelectedSkills();
         var _loc3_:PetCorpsSkill = null;
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc3_ = _loc2_[_loc4_];
            if(Boolean(_loc3_) && _loc3_.skillType == param1)
            {
               return _loc3_;
            }
            _loc4_++;
         }
         return null;
      }
      
      private function getTipsOffset() : Point
      {
         var _loc1_:int = this.getActivatedSkillNum();
         return this.SKILL_OFF_SETS[_loc1_];
      }
      
      private function getActivatedSkillNum() : int
      {
         var _loc3_:PetCorpsSkill = null;
         var _loc1_:Array = this.PET_CORPS_SERVICE.getCurSelectedSkills();
         var _loc2_:int = 0;
         for each(_loc3_ in _loc1_)
         {
            if(_loc3_)
            {
               _loc2_++;
            }
         }
         return _loc2_;
      }
      
      public function dispose() : void
      {
         this.PET_DATA_SERVICE.removeEventListener(PetDataServiceEvent.ON_HIGHTES_BATTLE_EFF_UPDATE,this.onHighestBEUpdated);
      }
   }
}

