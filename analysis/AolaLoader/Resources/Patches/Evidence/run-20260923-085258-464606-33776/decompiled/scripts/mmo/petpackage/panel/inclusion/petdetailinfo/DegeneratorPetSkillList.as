package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1331")]
   public class DegeneratorPetSkillList extends Sprite
   {
      
      public var mcskill0:MovieClip;
      
      public var mcskill1:MovieClip;
      
      public var mcskill2:MovieClip;
      
      public var mcskill3:MovieClip;
      
      public var mcskill4:MovieClip;
      
      private const EXTENSION_NAME:String = "";
      
      private const TOTAL_SKILL_NUM:int = 5;
      
      private var _petInfo:PetBriefInfo = null;
      
      private var _skillComponents:Array = [];
      
      private var _pmService:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      public function DegeneratorPetSkillList()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         var _loc1_:MovieClip = null;
         var _loc2_:int = 0;
         while(_loc2_ < this.TOTAL_SKILL_NUM)
         {
            _loc1_ = this.getChildByName("mcskill" + _loc2_) as MovieClip;
            this._skillComponents[_loc2_] = new DegeneratorPetSkillComponent(_loc1_);
            _loc2_++;
         }
         this.addEventListener(MouseEvent.CLICK,this.onClickView);
      }
      
      private function onClickView(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
      }
      
      public function refresh(param1:PetBriefInfo) : void
      {
         this._petInfo = param1;
         this.refreshView();
      }
      
      private function refreshView() : void
      {
         var _loc5_:PMSkill = null;
         var _loc1_:Array = this._petInfo.skills;
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_.length)
         {
            _loc5_ = this._pmService.customData.pmSkillMap.getSkill(_loc1_[_loc2_].id);
            if(_loc5_.getSkillType() == PMSkillTypes.DEGENERATOR_LOCK_SKILL || _loc5_.getSkillType() == PMSkillTypes.DEGENERATOR_COMMON_SPIRIT_PO)
            {
               _loc1_.push(this._petInfo.skills[_loc2_]);
               _loc1_.splice(_loc2_,1);
            }
            _loc2_++;
         }
         var _loc3_:DegeneratorPetSkillComponent = null;
         var _loc4_:int = 0;
         while(_loc4_ < this._skillComponents.length)
         {
            _loc3_ = this._skillComponents[_loc4_];
            _loc3_.refresh(_loc1_[_loc4_]);
            _loc4_++;
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:DegeneratorPetSkillComponent = null;
         for each(_loc1_ in this._skillComponents)
         {
            _loc1_.dispose();
         }
         this._skillComponents.length = 0;
      }
   }
}

