package mmo.petfightnew.common.util
{
   import flash.geom.Point;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.constant.FightSize;
   
   public class PositionUtil
   {
      
      private static const ORIGIN_SKILL_OFFSET:Point = new Point(440,140);
      
      private static const DEFENCE_BACK_OFF_RATE:Number = 0.1;
      
      private static const initPositionsIn1Vs1:Array = [new Point(669,440),new Point(612,490),new Point(486,445),new Point(684,445),new Point(612,490),new Point(576,493),new Point(85,320),new Point(130,380),new Point(170,265),new Point(172,365),new Point(130,380),new Point(185,270),new Point(500,320),new Point(320,280)];
      
      private static const initPositionsIn2Vs2:Array = [new Point(510,455),new Point(679,367),new Point(771,292),new Point(510,455),new Point(679,367),new Point(771,292),new Point(373,129),new Point(280,198),new Point(111,320),new Point(373,129),new Point(280,198),new Point(111,320),new Point(500,320),new Point(320,280)];
      
      private static const initPositionsIn3Vs3:Array = [new Point(589,378),new Point(690,309),new Point(496,455),new Point(676,423),new Point(777,354),new Point(586,503),new Point(60,354),new Point(257,197),new Point(158,275),new Point(117,437),new Point(352,211),new Point(234,324),new Point(510,330),new Point(310,270)];
      
      private static const initPositionsIn2Vs3:Array = [new Point(589,378),new Point(690,309),new Point(496,455),new Point(676,423),new Point(777,354),new Point(586,503),new Point(75,310),new Point(265,160),new Point(164,228),new Point(162,355),new Point(352,204),new Point(251,273),new Point(510,330),new Point(310,270)];
      
      private static const initPositionsIn6Vs6:Array = [new Point(589,378),new Point(690,309),new Point(496,455),new Point(676,423),new Point(777,354),new Point(586,503),new Point(75,310),new Point(265,160),new Point(164,228),new Point(162,355),new Point(352,204),new Point(251,273),new Point(510,330),new Point(310,270)];
      
      private static const useSkillPoistions:Object = {};
      
      private static const defendPoistions:Array = [];
      
      public function PositionUtil()
      {
         super();
      }
      
      public static function getDefaultPosition(param1:int) : Point
      {
         var _loc4_:PlayerBattleInfo = null;
         var _loc5_:PetBriefInfo = null;
         var _loc2_:int = FightData.instance.fightSize;
         var _loc3_:Array = null;
         switch(_loc2_)
         {
            case FightSize.ONE_VS_ONE:
               _loc3_ = initPositionsIn1Vs1;
               break;
            case FightSize.XH_ONE_VS_ONE:
               _loc3_ = initPositionsIn1Vs1;
               break;
            case FightSize.TWO_VS_TWO:
               _loc3_ = initPositionsIn2Vs2;
               break;
            case FightSize.THREE_VS_THREE:
               _loc3_ = initPositionsIn3Vs3;
               break;
            case FightSize.TWO_VS_THREE:
               _loc3_ = initPositionsIn2Vs3;
               break;
            default:
               _loc3_ = initPositionsIn6Vs6;
         }
         if(BSUtil.getIsInHunDunJueDouState())
         {
            _loc4_ = FightData.instance.getPlayerInfoByLocalId(param1);
            if((_loc4_) && _loc4_.myPets && _loc4_.myPets.length > 0)
            {
               _loc5_ = _loc4_.myPets[0];
               if(_loc5_)
               {
                  if(StatusUtil.getIsInHunDunJueDouState(_loc5_))
                  {
                     if(FightData.instance.isMySide(param1))
                     {
                        return new Point(669,440);
                     }
                     return new Point(185,270);
                  }
               }
            }
         }
         if(_loc2_ == FightSize.TWO_VS_TWO)
         {
            _loc4_ = FightData.instance.getPlayerInfoByLocalId(param1);
            if((_loc4_) && _loc4_.myPets && _loc4_.myPets.length > 0)
            {
               _loc5_ = _loc4_.myPets[0];
               if((Boolean(_loc5_)) && (StatusUtil.getIsDengShenChangJieSpiritSkillUsed(_loc5_) || StatusUtil.getIsInJiangShenState(_loc5_) || StatusUtil.getIsZhenLiFaDianSpiritSkillUsed(_loc5_)))
               {
                  if(FightData.instance.isMySide(param1))
                  {
                     return new Point(690,510);
                  }
                  return new Point(230,400);
               }
            }
         }
         return _loc3_[param1];
      }
      
      public static function getUseSkillPosition(param1:int, param2:int) : Point
      {
         var _loc3_:int = FightData.instance.getSlotId(param1);
         var _loc4_:PlayerBattleInfo = FightData.instance.getPlayerInfoBySlotId(_loc3_);
         var _loc5_:PetBriefInfo = _loc4_.myPets[0];
         var _loc6_:int = int(PetAssetsMap.getPetFlaId(_loc5_.viewId));
         var _loc7_:Number = FightData.instance.getPetHitDistanceScale(_loc6_);
         var _loc8_:Point = getDefaultPosition(param2);
         var _loc9_:int = param1 <= FightData.MARK_LOCA_ID || param1 == FightData.SHENG_LING_POS_WE ? 1 : -1;
         var _loc10_:Number = ORIGIN_SKILL_OFFSET.x * _loc7_;
         var _loc11_:Number = ORIGIN_SKILL_OFFSET.y * _loc7_;
         var _loc12_:Point = getDefaultPosition(param1);
         var _loc13_:Number = Math.abs(_loc8_.x - _loc12_.x);
         var _loc14_:Number = Math.abs(_loc8_.y - _loc12_.y);
         _loc10_ = Math.min(_loc13_,_loc10_);
         _loc11_ = Math.min(_loc14_,_loc11_);
         _loc10_ *= _loc9_;
         _loc11_ *= _loc9_;
         var _loc15_:Number = _loc8_.x + _loc10_;
         var _loc16_:Number = _loc8_.y + _loc11_;
         return new Point(_loc15_,_loc16_);
      }
      
      public static function getDefendPosition(param1:int) : Point
      {
         var _loc4_:Point = null;
         var _loc5_:int = 0;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc2_:Array = defendPoistions;
         var _loc3_:Point = _loc2_[param1];
         if(_loc3_ == null)
         {
            _loc4_ = getDefaultPosition(param1);
            _loc5_ = param1 <= FightData.MARK_LOCA_ID || param1 == FightData.SHENG_LING_POS_WE ? 1 : -1;
            _loc6_ = ORIGIN_SKILL_OFFSET.x * DEFENCE_BACK_OFF_RATE * _loc5_;
            _loc7_ = ORIGIN_SKILL_OFFSET.y * DEFENCE_BACK_OFF_RATE * _loc5_;
            _loc8_ = _loc4_.x + _loc6_;
            _loc9_ = _loc4_.y + _loc7_;
            _loc3_ = new Point(_loc8_,_loc9_);
            _loc2_[param1] = _loc3_;
         }
         return _loc3_;
      }
   }
}

