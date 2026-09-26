package mmo.petfightnew.common.panel.skill.small
{
   import flash.display.MovieClip;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.petfightnew.common.data.PetState;
   import mmo.petfightnew.common.data.PetType;
   import mmo.petfightnew.common.util.StatusUtil;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1409")]
   public class EmptySkillMC extends MovieClip
   {
      
      public function EmptySkillMC()
      {
         super();
         this.stop();
      }
      
      public function update(param1:PetBriefInfo) : void
      {
         var _loc2_:int = PetType.getPetType(param1);
         var _loc3_:int = PetState.getPetState(param1);
         if(_loc2_ == PetType.GOT_SKILL_AOYI)
         {
            this.gotoAndStop(3);
         }
         else if(PetType.isLegendPet(_loc2_))
         {
            this.gotoAndStop(6);
         }
         else if(_loc2_ == PetType.DEGENERATOR)
         {
            this.gotoAndStop(9);
         }
         else if(_loc2_ == PetType.XINGHUI)
         {
            if(param1.isShielded())
            {
               this.gotoAndStop(11);
            }
            else
            {
               this.gotoAndStop(10);
            }
         }
         else if(StatusUtil.getIsInJiangShenState(param1) || StatusUtil.getIsGuiLingXieYiDataBody(param1))
         {
            this.gotoAndStop(13);
         }
         else if(_loc2_ == PetType.GQ)
         {
            this.gotoAndStop(12);
         }
         else if(_loc3_ == PetState.CHANGING_VIEW)
         {
            this.gotoAndStop(2);
         }
         else if(_loc2_ == PetType.MIRACLE)
         {
            this.gotoAndStop(4);
         }
         else
         {
            this.gotoAndStop(1);
         }
      }
   }
}

