package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.interfaces.pet.data.PetBriefInfo;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1359")]
   public class LegendPetSkillList extends Sprite
   {
      
      public var mcskill0:MovieClip;
      
      public var mcskill1:MovieClip;
      
      public var mcskill2:MovieClip;
      
      public var mcskill3:MovieClip;
      
      private const EXTENSION_NAME:String = "";
      
      private const TOTAL_SKILL_NUM:int = 4;
      
      private var _petInfo:PetBriefInfo = null;
      
      private var _skillComponents:Array = [];
      
      public function LegendPetSkillList()
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
            this._skillComponents[_loc2_] = new LegendPetSkillComponent(_loc1_);
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
         var _loc1_:LegendPetSkillComponent = null;
         var _loc2_:int = 0;
         while(_loc2_ < this._skillComponents.length)
         {
            _loc1_ = this._skillComponents[_loc2_];
            _loc1_.refresh(this._petInfo.skills[_loc2_]);
            _loc2_++;
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:LegendPetSkillComponent = null;
         for each(_loc1_ in this._skillComponents)
         {
            _loc1_.dispose();
         }
         this._skillComponents.length = 0;
      }
   }
}

