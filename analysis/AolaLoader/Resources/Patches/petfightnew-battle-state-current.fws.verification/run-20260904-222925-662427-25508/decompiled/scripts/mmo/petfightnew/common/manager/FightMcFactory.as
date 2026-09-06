package mmo.petfightnew.common.manager
{
   import flash.display.MovieClip;
   import flash.utils.getDefinitionByName;
   import mmo.petfightnew.common.util.DisableUtil;
   
   public class FightMcFactory
   {
      
      public function FightMcFactory()
      {
         super();
      }
      
      public static function getFightMcByKey(param1:String) : MovieClip
      {
         var _loc2_:MovieClip = FightMcPool.instance.getMcByKey(param1);
         if(_loc2_ != null)
         {
            return _loc2_;
         }
         switch(param1)
         {
            case FightMcKeys.McCriticalHit:
               _loc2_ = getMovieClip("mmo.petfightnew.common.McCriticalHit");
               break;
            case FightMcKeys.McNoEffect:
               _loc2_ = getMovieClip("mmo.petfightnew.common.movies.NoEffectMovie");
               break;
            case FightMcKeys.HurtMovie:
               _loc2_ = getMovieClip("mmo.petfightnew.common.movies.HurtMovie");
               break;
            case FightMcKeys.McSkillName:
               _loc2_ = getMovieClip("mmo.petfightnew.common.McSkillName");
               break;
            case FightMcKeys.StopMovie:
               _loc2_ = getMovieClip("mmo.petfightnew.common.movies.StopMovie");
               break;
            case FightMcKeys.Miss:
               _loc2_ = getMovieClip("mmo.petfightnew.common.MissMovie");
               break;
            case FightMcKeys.NormalDecHp:
               _loc2_ = getMovieClip("mmo.petfightnew.common.useskill.NormalDecHp");
               break;
            case FightMcKeys.StrongDecHp:
               _loc2_ = getMovieClip("mmo.petfightnew.common.useskill.StrongDecHp");
               break;
            case FightMcKeys.AddHp:
               _loc2_ = getMovieClip("mmo.petfightnew.common.useskill.AddHp");
               break;
            case FightMcKeys.MultipleDecHp:
               _loc2_ = getMovieClip("mmo.petfightnew.common.useskill.MultipleDecHp");
               break;
            case FightMcKeys.McReallyHit:
               _loc2_ = getMovieClip("mmo.petfightnew.common.useskill.ReallyDecHp");
               break;
            case FightMcKeys.AllHitHp:
               _loc2_ = getMovieClip("mmo.petfightnew.common.useskill.AllHitHp");
               break;
            case FightMcKeys.MultipleTimes:
               _loc2_ = getMovieClip("mmo.petfightnew.common.useskill.MultipleTimesMovie");
               break;
            case FightMcKeys.GQHurtMovie:
               _loc2_ = getMovieClip("mmmo.petfightnew.common.movies.GQHurtMovie");
               break;
            case FightMcKeys.McShieldHit:
               _loc2_ = getMovieClip("mmo.petfightnew.common.useskill.ShieldHitHp");
               break;
            case FightMcKeys.McReallyShieldHit:
               _loc2_ = getMovieClip("mmo.petfightnew.common.useskill.ReallyShieldHit");
         }
         DisableUtil.disableAll(_loc2_);
         return _loc2_;
      }
      
      private static function getMovieClip(param1:String) : MovieClip
      {
         var _loc2_:Class = getDefinitionByName(param1) as Class;
         return new _loc2_() as MovieClip;
      }
   }
}

