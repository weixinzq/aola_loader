package mmo.petfightnew.common.panel
{
   import flash.display.Sprite;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol434")]
   public class PetSkillTips extends Sprite
   {
      
      private static const MAX_SKILL_NUM:int = 4;
      
      public var _detailList:Array = [];
      
      public function PetSkillTips()
      {
         super();
      }
      
      public function update(param1:PetBriefInfo) : void
      {
         var _loc3_:PetSkillTipsDetail = null;
         var _loc4_:SkillInfo = null;
         var _loc2_:int = 0;
         while(_loc2_ < MAX_SKILL_NUM)
         {
            _loc3_ = this._detailList[_loc2_];
            _loc4_ = param1.skills[_loc2_];
            if(_loc4_ == null)
            {
               if(_loc3_)
               {
                  _loc3_.visible = false;
               }
            }
            else
            {
               if(_loc3_ == null)
               {
                  _loc3_ = new PetSkillTipsDetail();
                  _loc3_.x = 4.4;
                  _loc3_.y = 4.25 + 29 * _loc2_;
                  this.addChild(_loc3_);
               }
               else
               {
                  _loc3_.visible = true;
               }
               _loc3_.update(_loc4_);
            }
            _loc2_++;
         }
      }
   }
}

