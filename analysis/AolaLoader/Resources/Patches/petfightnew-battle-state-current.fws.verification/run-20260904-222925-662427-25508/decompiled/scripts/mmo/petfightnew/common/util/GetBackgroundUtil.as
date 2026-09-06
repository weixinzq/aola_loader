package mmo.petfightnew.common.util
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import mmo.petfightnew.common.FightData;
   
   public class GetBackgroundUtil
   {
      
      private static var backs:Array;
      
      public function GetBackgroundUtil()
      {
         super();
      }
      
      private static function init() : void
      {
         if(backs != null)
         {
            return;
         }
         backs = [];
         backs["aixiscene1"] = ["mmo.petfight.IceBack","petfightbackground/aixi"];
         backs["aixiscene2"] = ["mmo.petfight.IceBack","petfightbackground/aixi"];
         backs["aixiscene3"] = ["mmo.petfight.IceBack","petfightbackground/aixi"];
         backs["aixiscene4"] = ["mmo.petfight.IceBack","petfightbackground/aixi"];
         backs["suolide1"] = ["mmo.petfight.SuolideBack","petfightbackground/suolide"];
         backs["suolide2"] = ["mmo.petfight.SuolideBack","petfightbackground/suolide"];
         backs["suolide3"] = ["mmo.petfight.SuolideBack","petfightbackground/suolide"];
         backs["suolide4"] = ["mmo.petfight.SuolideBack","petfightbackground/suolide"];
         backs["siwude1"] = ["mmo.petfight.SiwudeBack","petfightbackground/siwude"];
         backs["siwude2"] = ["mmo.petfight.SiwudeBack","petfightbackground/siwude"];
         backs["siwude3"] = ["mmo.petfight.SiwudeBack","petfightbackground/siwude"];
         backs["siwude4"] = ["mmo.petfight.SiwudeBack","petfightbackground/siwude"];
         backs["siwude5"] = ["mmo.petfight.SiwudeBack","petfightbackground/siwude"];
         backs["siwude6"] = ["mmo.petfight.SiwudeBack","petfightbackground/siwude"];
         backs["woerte1"] = ["mmo.petfight.WoerteBack","petfightbackground/woerte"];
         backs["woerte2"] = ["mmo.petfight.WoerteBack","petfightbackground/woerte"];
         backs["woerte3"] = ["mmo.petfight.WoerteBack","petfightbackground/woerte"];
         backs["woerte4"] = ["mmo.petfight.WoerteBack","petfightbackground/woerte"];
         backs["feier1"] = ["mmo.petfight.FeierBack","petfightbackground/feier"];
         backs["feier2"] = ["mmo.petfight.FeierBack","petfightbackground/feier"];
         backs["feier3"] = ["mmo.petfight.FeierBack","petfightbackground/feier"];
         backs["feier4"] = ["mmo.petfight.FeierBack","petfightbackground/feier"];
         backs["spacetimefb"] = ["mmo.petfight.SpaceTimeBack","petfightbackground/spacetime"];
         backs["spacetimeboss"] = ["mmo.petfight.SpaceTimeBack","petfightbackground/spacetime"];
         backs["fbaixi1"] = ["mmo.petfight.IceCopyBack","petfightbackground/fbice"];
         backs["fbaixi2"] = ["mmo.petfight.IceCopyBack","petfightbackground/fbice"];
         backs["fbaixi3"] = ["mmo.petfight.IceCopyBack","petfightbackground/fbice"];
         backs["fbaixi4"] = ["mmo.petfight.IceCopyBack","petfightbackground/fbice"];
         backs["fbaixi5"] = ["mmo.petfight.IceCopyBack","petfightbackground/fbice"];
         backs["fbaixi6"] = ["mmo.petfight.IceCopyBack","petfightbackground/fbice"];
         backs["fbaixi7"] = ["mmo.petfight.IceCopyBack","petfightbackground/fbice"];
         backs["fbaixi8"] = ["mmo.petfight.IceCopyBack","petfightbackground/fbice"];
         backs["fbaixi9"] = ["mmo.petfight.IceCopyBack","petfightbackground/fbice"];
         backs["bite1"] = ["mmo.petfight.BiteBack","petfightbackground/bite"];
         backs["bite2"] = ["mmo.petfight.BiteBack","petfightbackground/bite"];
         backs["bite3"] = ["mmo.petfight.BiteBack","petfightbackground/bite"];
         backs["bite4"] = ["mmo.petfight.BiteBack","petfightbackground/bite"];
         backs["haiwen1"] = ["mmo.petfight.HaiwenBack","petfightbackground/haiwen"];
         backs["haiwen2"] = ["mmo.petfight.HaiwenBack","petfightbackground/haiwen"];
         backs["haiwen3"] = ["mmo.petfight.HaiwenBack","petfightbackground/haiwen"];
         backs["haiwen4"] = ["mmo.petfight.HaiwenBack","petfightbackground/haiwen"];
         backs["haiwen5"] = ["mmo.petfight.HaiwenBack","petfightbackground/haiwen"];
         backs["leiming1"] = ["mmo.petfight.LeiMingBack","petfightbackground/leiming"];
         backs["leiming2"] = ["mmo.petfight.LeiMingBack","petfightbackground/leiming"];
         backs["leiming3"] = ["mmo.petfight.LeiMingBack","petfightbackground/leiming"];
         backs["leiming4"] = ["mmo.petfight.LeiMingBack","petfightbackground/leiming"];
         backs["fbsiwude"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["fbsiwude1"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["fbsiwude2"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["fbsiwude3"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["fbsiwude4"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["fbsiwude5"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["fbsiwude6"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["fbsiwude7"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["fbsiwude8"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["fbsiwude9"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["fbsiwude10"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["fbsiwude11"] = ["mmo.petfight.FBSiwudeBack","petfightbackground/fbsiwude"];
         backs["yishuzhidu1"] = ["mmo.petfight.YishuzhiduBack","petfightbackground/yishuzhidu"];
         backs["yishuzhidu2"] = ["mmo.petfight.YishuzhiduBack","petfightbackground/yishuzhidu"];
         backs["yishuzhidu3"] = ["mmo.petfight.YishuzhiduBack","petfightbackground/yishuzhidu"];
         backs["yishuzhidu4"] = ["mmo.petfight.YishuzhiduBack","petfightbackground/yishuzhidu"];
         backs["yishuzhidu5"] = ["mmo.petfight.YishuzhiduBack","petfightbackground/yishuzhidu"];
         backs["aquarium"] = ["mmo.petfight.YishuzhiduBack","petfightbackground/yishuzhidu"];
         backs["inventisland1"] = ["mmo.petfight.InventBack","petfightbackground/invent"];
         backs["inventisland2"] = ["mmo.petfight.InventBack","petfightbackground/invent"];
         backs["inventisland3"] = ["mmo.petfight.InventBack","petfightbackground/invent"];
         backs["inventisland4"] = ["mmo.petfight.InventBack","petfightbackground/invent"];
         backs["inventisland5"] = ["mmo.petfight.InventBack","petfightbackground/invent"];
         backs["spacetimechallenge"] = ["mmo.petfight.PetofkingBack","petfightbackground/petofking"];
         backs["emptyspace1"] = ["mmo.petfight.EmptySpace","petfightbackground/emptyspace"];
         backs["emptyspace2"] = ["mmo.petfight.EmptySpace","petfightbackground/emptyspace"];
         backs["fightspace1"] = ["mmo.petfight.FightSpace","petfightbackground/fightspace"];
         backs["fightspace2"] = ["mmo.petfight.FightSpace","petfightbackground/fightspace"];
         backs["fightspace3"] = ["mmo.petfight.FightSpace","petfightbackground/fightspace"];
         backs["waterhole"] = ["mmo.petfight.FightSpace","petfightbackground/fightspace"];
         backs["cubemansion"] = ["mmo.petfight.Cube","petfightbackground/cube"];
         backs["mazecube"] = ["mmo.petfight.Cube","petfightbackground/cube"];
         backs["giantcordillera1"] = ["mmo.petfight.GiantCordillera","petfightbackground/giantcordillera"];
         backs["giantcordillera2"] = ["mmo.petfight.GiantCordillera","petfightbackground/giantcordillera"];
         backs["giantcordillera3"] = ["mmo.petfight.GiantCordillera","petfightbackground/giantcordillera"];
         backs["giantcordillera4"] = ["mmo.petfight.GiantCordillera","petfightbackground/giantcordillera"];
         backs["giantcordillera5"] = ["mmo.petfight.GiantCordillera","petfightbackground/giantcordillera"];
         backs["temple4"] = ["mmo.petfight.XuanWu","petfightbackground/xuanwu"];
         backs["temple5"] = ["mmo.petfight.XuanWu","petfightbackground/xuanwu"];
         backs["mantenxiagu1"] = ["mmo.petfight.ManTengXiaGu","petfightbackground/mantengxiagu"];
         backs["mantenxiagu2"] = ["mmo.petfight.ManTengXiaGu","petfightbackground/mantengxiagu"];
         backs["mantenxiagu3"] = ["mmo.petfight.ManTengXiaGu","petfightbackground/mantengxiagu"];
         backs["starsea1"] = ["mmo.petfight.StarSea","petfightbackground/starsea"];
         backs["starsea2"] = ["mmo.petfight.StarSea","petfightbackground/starsea"];
         backs["temple11"] = ["mmo.petfight.GreenDragon","petfightbackground/greendragon"];
         backs["temple1"] = ["mmo.petfight.Boss10105BackGround","petfightbackground/temple1"];
         backs["temple16"] = ["mmo.petfight.Temple16","petfightbackground/temple16"];
         backs["temple17"] = ["mmo.petfight.Temple16","petfightbackground/temple16"];
         backs["bastion"] = ["mmo.petfight.Bastion","petfightbackground/bastion"];
         backs["youanmingzhou1"] = ["mmo.petfight.YouanmingzhouBack","petfightbackground/youanmingzhou"];
         backs["youanmingzhou2"] = ["mmo.petfight.YouanmingzhouBack","petfightbackground/youanmingzhou"];
         backs["youanmingzhou3"] = ["mmo.petfight.YouanmingzhouBack","petfightbackground/youanmingzhou"];
         backs["youanmingzhou4"] = ["mmo.petfight.YouanmingzhouBack","petfightbackground/youanmingzhou"];
         backs["choicetemple"] = ["mmo.petfight.ChoiceTemple","petfightbackground/choicetemple"];
         backs["thinktowerofwater"] = ["mmo.petfight.Thinktowerofwater","petfightbackground/thinktowerofwater"];
         backs["thinktoweroffire"] = ["mmo.petfight.Thinktoweroffire","petfightbackground/thinktoweroffire"];
         backs["thinktowerofice"] = ["mmo.petfight.Thinktowerofice","petfightbackground/thinktowerofice"];
         backs["thinktowerofthunder"] = ["mmo.petfight.Thinktowerofthunder","petfightbackground/thinktowerofthunder"];
         backs["thinktowerofnian"] = ["mmo.petfight.ThinkTowerOfNianBack","petfightbackground/thinktowerofnian"];
         backs["thinktowerofthink"] = ["mmo.petfight.ThinkTowerOfNianBack","petfightbackground/thinktowerofnian"];
         backs["home"] = ["mmo.petfight.Home","petfightbackground/home"];
         backs["unicornstar1"] = ["mmo.petfight.UnicornStar1","petfightbackground/unicornstar1"];
         backs["unicornstar2"] = ["mmo.petfight.UnicornStar2","petfightbackground/unicornstar2"];
         backs["unicornstar4"] = ["mmo.petfight.UnicornStar4","petfightbackground/unicornstar4"];
         backs["unicornstar3"] = ["mmo.petfight.UnicornStar2","petfightbackground/unicornstar2"];
         backs["unicornstar5"] = ["mmo.petfight.UnicornStar1","petfightbackground/unicornstar1"];
         backs["fairytalestar1"] = ["mmo.petfight.FairyTaleStar1","petfightbackground/fairytalestar1"];
         backs["fairytalestar2"] = ["mmo.petfight.FairyTaleStar1","petfightbackground/fairytalestar1"];
         backs["fairytalestar3"] = ["mmo.petfight.FairyTaleStar1","petfightbackground/fairytalestar1"];
         backs["magicstar1"] = ["mmo.petfight.MagicStar1","petfightbackground/magicstar1"];
         backs["magicstar2"] = ["mmo.petfight.MagicStar1","petfightbackground/magicstar1"];
         backs["haikustar1"] = ["mmo.petfight.HaikuStar","petfightbackground/haikustar"];
         backs["haikustar2"] = ["mmo.petfight.HaikuStar","petfightbackground/haikustar"];
         backs["haikustar3"] = ["mmo.petfight.HaikuStar","petfightbackground/haikustar"];
         backs["haikustar4"] = ["mmo.petfight.HaikuStar","petfightbackground/haikustar"];
         backs["bingxuestar1"] = ["mmo.petfight.BingxueStar","petfightbackground/bingxuestar"];
         backs["bingxuestar2"] = ["mmo.petfight.BingxueStar","petfightbackground/bingxuestar"];
         backs["bingxuestar3"] = ["mmo.petfight.BingxueStar","petfightbackground/bingxuestar"];
         backs["msevenstar1"] = ["mmo.petfight.MSevenStar","petfightbackground/msevenstar"];
         backs["themepark"] = ["mmo.petfight.ThemePark","petfightbackground/themepark"];
         backs["hexagrampalace1"] = ["mmo.petfight.HexagramPalace","petfightbackground/hexagrampalace"];
         backs["hexagrampalace2"] = ["mmo.petfight.HexagramPalace","petfightbackground/hexagrampalace"];
         backs["yakestar1"] = ["mmo.petfight.YaKeStar","petfightbackground/yakestar"];
         backs["yakestar2"] = ["mmo.petfight.YaKeStar","petfightbackground/yakestar"];
         backs["yakestar3"] = ["mmo.petfight.YaKeStar","petfightbackground/yakestar"];
         backs["yakestar4"] = ["mmo.petfight.YaKeStar","petfightbackground/yakestar"];
         backs["candystar1"] = ["mmo.petfight.CandyStar","petfightbackground/candystar"];
         backs["candystar2"] = ["mmo.petfight.CandyStar","petfightbackground/candystar"];
         backs["candystar3"] = ["mmo.petfight.CandyStar","petfightbackground/candystar"];
         backs["windmillstar1"] = ["mmo.petfight.WindMillStar","petfightbackground/windmillstar"];
         backs["windmillstar2"] = ["mmo.petfight.WindMillStar","petfightbackground/windmillstar"];
         backs["windmillstar3"] = ["mmo.petfight.WindMillStar","petfightbackground/windmillstar"];
         backs["windmillstar4"] = ["mmo.petfight.WindMillStar","petfightbackground/windmillstar"];
         backs["clockstar1"] = ["mmo.petfight.ClockStar","petfightbackground/clockstar"];
         backs["clockstar2"] = ["mmo.petfight.ClockStar","petfightbackground/clockstar"];
         backs["clockstar3"] = ["mmo.petfight.ClockStar","petfightbackground/clockstar"];
         backs["clockstar4"] = ["mmo.petfight.ClockStar","petfightbackground/clockstar"];
         backs["fightkingwar1"] = ["mmo.petfight.Fightkingwar","petfightbackground/fightkingwar"];
         backs["fightkingwar2"] = ["mmo.petfight.Fightkingwar","petfightbackground/fightkingwar"];
         backs["fightkingwar3"] = ["mmo.petfight.Fightkingwar","petfightbackground/fightkingwar"];
         backs["fightkingwar5"] = ["mmo.petfight.Fightkingwar","petfightbackground/fightkingwar"];
         backs["fightkingwar6"] = ["mmo.petfight.FightkingwarWl","petfightbackground/fightkingwarwl"];
         backs["fightkingwar8"] = ["mmo.petfight.Fightkingwar8","petfightbackground/fightkingwar8"];
         backs["fightkingwar9"] = ["mmo.petfight.Fightkingwar9","petfightbackground/fightkingwar9"];
         backs["knightstar1"] = ["mmo.petfight.KnightStar","petfightbackground/knightstar"];
         backs["knightstar2"] = ["mmo.petfight.KnightStar","petfightbackground/knightstar"];
         backs["knightstar3"] = ["mmo.petfight.KnightStar","petfightbackground/knightstar"];
         backs["knightstar4"] = ["mmo.petfight.KnightStar","petfightbackground/knightstar"];
         backs["screampark1"] = ["mmo.petfight.ScreamPark","petfightbackground/screampark"];
         backs["screampark2"] = ["mmo.petfight.ScreamPark","petfightbackground/screampark"];
         backs["screampark3"] = ["mmo.petfight.ScreamPark","petfightbackground/screampark"];
         backs["screampark4"] = ["mmo.petfight.ScreamPark","petfightbackground/screampark"];
         backs["junglecopy"] = ["mmo.petfight.IceBack","petfightbackground/aixi"];
         backs["teambattleoutside"] = ["mmo.petfight.TeamBattleOutSideBack","petfightbackground/teambattleoutside"];
         backs["musicstar1"] = ["mmo.petfight.MusicStar","petfightbackground/musicstar"];
         backs["musicstar2"] = ["mmo.petfight.MusicStar","petfightbackground/musicstar"];
         backs["bailingstar1"] = ["mmo.petfight.BaiLingStar","petfightbackground/bailingstar"];
         backs["bailingstar2"] = ["mmo.petfight.BaiLingStar","petfightbackground/bailingstar"];
         backs["skycity1"] = ["mmo.petfight.SkyCity","petfightbackground/skycity"];
         backs["skycity2"] = ["mmo.petfight.SkyCity","petfightbackground/skycity"];
         backs["skycity3"] = ["mmo.petfight.SkyCity3","petfightbackground/skycity3"];
         backs["skycity4"] = ["mmo.petfight.SkyCity4","petfightbackground/skycity4"];
         backs["cloudstar1"] = ["mmo.petfight.CloudStar1","petfightbackground/cloudstar1"];
         backs["cloudstar2"] = ["mmo.petfight.CloudStar1","petfightbackground/cloudstar1"];
         backs["cloudstar3"] = ["mmo.petfight.CloudStar1","petfightbackground/cloudstar1"];
         backs["mysticearth1"] = ["mmo.petfight.MysticEarth1","petfightbackground/mysticearth1"];
         backs["mysticearth2"] = ["mmo.petfight.MysticEarth1","petfightbackground/mysticearth1"];
         backs["mysticearth3"] = ["mmo.petfight.MysticEarth1","petfightbackground/mysticearth1"];
         backs["mysticearth4"] = ["mmo.petfight.MysticEarth1","petfightbackground/mysticearth1"];
         backs["mysticocean1"] = ["mmo.petfight.MysticOcean1","petfightbackground/mysticocean1"];
         backs["mysticocean2"] = ["mmo.petfight.MysticOcean1","petfightbackground/mysticocean1"];
         backs["mysticocean3"] = ["mmo.petfight.MysticOcean1","petfightbackground/mysticocean1"];
         backs["mysticocean4"] = ["mmo.petfight.MysticOcean1","petfightbackground/mysticocean1"];
         backs["mysticocean5"] = ["mmo.petfight.MysticOcean1","petfightbackground/mysticocean1"];
         backs["hallowmas"] = ["mmo.petfight.ThemePark","petfightbackground/themepark"];
         backs["huanyan"] = ["mmo.petfight.HuanYan","petfightbackground/huanyan"];
         backs["huanliu"] = ["mmo.petfight.HuanLiu","petfightbackground/huanliu"];
         backs["huanlei"] = ["mmo.petfight.HuanLei","petfightbackground/huanlei"];
         backs["whitenight0"] = ["mmo.petfight.WhiteNight","petfightbackground/whitenight"];
         backs["whitenight1"] = ["mmo.petfight.WhiteNight","petfightbackground/whitenight"];
         backs["whitenight2"] = ["mmo.petfight.WhiteNight","petfightbackground/whitenight"];
         backs["whitenight3"] = ["mmo.petfight.WhiteNight","petfightbackground/whitenight"];
         backs["zodiac2"] = ["mmo.petfight.Zodiac2","petfightbackground/zodiac2"];
         backs["starshinecity0"] = ["mmo.petfight.StarShineCity","petfightbackground/starshinecity"];
         backs["magicringforest0"] = ["mmo.petfight.MagicRingForest","petfightbackground/magicringforest"];
         backs["majicorsair0"] = ["mmo.petfight.MajiCorsair","petfightbackground/majicorsair"];
         backs["majicorsair1"] = ["mmo.petfight.MajiCorsair1","petfightbackground/majicorsair1"];
         backs["holysword0"] = ["mmo.petfight.HolySword","petfightbackground/holysword"];
         backs["holysword1"] = ["mmo.petfight.HolySword1","petfightbackground/holysword1"];
         backs["holysword2"] = ["mmo.petfight.HolySword2","petfightbackground/holysword2"];
         backs["holysword3"] = ["mmo.petfight.HolySword3","petfightbackground/holysword3"];
         backs["godice0"] = ["mmo.petfight.GodIce0","petfightbackground/godice0"];
         backs["godice1"] = ["mmo.petfight.GodIce1","petfightbackground/godice1"];
         backs["godice3"] = ["mmo.petfight.GodIce3","petfightbackground/godice3"];
         backs["newheroking0"] = ["mmo.petfight.NewHeroKing0","petfightbackground/newheroking0"];
         backs["xhtz0"] = ["mmo.petfight.Xhtz0","petfightbackground/xhtz0"];
         backs["xhtz1"] = ["mmo.petfight.Xhtz1","petfightbackground/xhtz1"];
         backs["xhtz2"] = ["mmo.petfight.Xhtz2","petfightbackground/xhtz2"];
         backs["legendcup"] = ["mmo.petfight.LegendCup","petfightbackground/legendcup"];
      }
      
      public static function getBackground(param1:String) : DisplayObject
      {
         var _loc2_:String = null;
         var _loc4_:Class = null;
         var _loc5_:DisplayObject = null;
         init();
         var _loc3_:Array = backs[param1];
         if(FightData.instance.haveGQPet)
         {
            _loc2_ = "mmo.petfight.GQcommonBack";
         }
         else if(_loc3_ == null)
         {
            if(FightData.instance.haveXinghuiPet)
            {
               _loc2_ = "mmo.petfight.XinghuicommonBack";
            }
            else
            {
               _loc2_ = "mmo.petfight.CommonBack";
            }
         }
         else
         {
            _loc2_ = _loc3_[0];
         }
         if(FightData.instance.applicationDomain.hasDefinition(_loc2_))
         {
            _loc4_ = FightData.instance.applicationDomain.getDefinition(_loc2_) as Class;
            _loc5_ = new _loc4_();
         }
         else
         {
            _loc5_ = new Sprite();
         }
         return _loc5_;
      }
      
      public static function getFileName(param1:String) : String
      {
         var _loc2_:String = null;
         init();
         var _loc3_:Array = backs[param1];
         if(FightData.instance.haveGQPet)
         {
            _loc2_ = "petfightbackground/common";
         }
         else if(_loc3_ == null)
         {
            _loc2_ = "petfightbackground/common";
         }
         else
         {
            _loc2_ = _loc3_[1];
         }
         return _loc2_;
      }
      
      public static function changeBackgroundRes(param1:String, param2:String, param3:String) : void
      {
         init();
         backs[param1] = [param3,param2];
      }
      
      public static function resetBackgroundRes() : void
      {
         backs = null;
         init();
      }
   }
}

