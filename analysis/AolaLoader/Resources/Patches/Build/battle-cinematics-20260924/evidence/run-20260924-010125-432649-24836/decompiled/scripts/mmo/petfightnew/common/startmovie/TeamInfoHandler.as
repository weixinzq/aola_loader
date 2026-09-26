package mmo.petfightnew.common.startmovie
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.interfaces.material.headframe.HeadFrameFactory;
   import mmo.interfaces.material.headframe.HeadFrameSize;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   
   public class TeamInfoHandler
   {
      
      public function TeamInfoHandler()
      {
         super();
      }
      
      public function handleTeam(param1:Array, param2:MovieClip, param3:Boolean = false) : void
      {
         var _loc5_:Array = null;
         var _loc11_:PlayerBattleInfo = null;
         var _loc4_:Array = [];
         _loc5_ = [];
         var _loc6_:Array = [];
         param2.mouseEnabled = param2.mouseChildren = false;
         param2.gotoAndStop(1);
         var _loc7_:Sprite = param2.getChildByName("spPlayerInfo0") as Sprite;
         var _loc8_:PlayerBattleInfo = (param1[0] as PlayerBattleInfo).clone();
         _loc8_.setPackageBattlePower(0);
         _loc8_.setPetCorpsBattlePower(0);
         _loc8_.setSummonerBattlePower(0);
         _loc8_.setPMCanBattle(0);
         var _loc9_:int = 0;
         while(_loc9_ < param1.length)
         {
            _loc11_ = param1[_loc9_] as PlayerBattleInfo;
            _loc8_.setPackageBattlePower(_loc8_.packageBattlePower + _loc11_.packageBattlePower);
            _loc8_.setPetCorpsBattlePower(_loc8_.petCorpsBattlePower + _loc11_.petCorpsBattlePower);
            _loc8_.setSummonerBattlePower(_loc8_.summonerBattlePower + _loc11_.summonerBattlePower);
            _loc8_.setPMCanBattle(_loc8_.PMCanBattle + _loc11_.PMCanBattle);
            _loc9_++;
         }
         _loc4_.push((param1[0] as PlayerBattleInfo).userName);
         var _loc10_:Sprite = new Sprite();
         _loc10_.mouseEnabled = _loc10_.mouseChildren = false;
         _loc5_.push(_loc10_);
         _loc6_.push(param3 ? -1 : 1);
         new PlayerInfoHandler().handlePlayerInfo(_loc8_,_loc7_,_loc5_[0]);
         if(param1.length > 0)
         {
            HeadFrameFactory.createHeadFrameByContainer(_loc4_,_loc5_,param2,HeadFrameSize.BIG,_loc6_,null,false,true,false);
         }
      }
   }
}

