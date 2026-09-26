package mmo.petfightnew.common.useskill
{
   import mmo.interfaces.pet.data.PetBriefInfo;
   
   public interface IUseSkillStrategy
   {
      
      function useSkill(param1:PetBriefInfo) : int;
   }
}

