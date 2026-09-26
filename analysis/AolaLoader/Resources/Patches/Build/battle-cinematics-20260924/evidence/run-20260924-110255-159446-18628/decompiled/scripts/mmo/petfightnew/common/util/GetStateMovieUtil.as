package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightMcCache;
   
   public class GetStateMovieUtil
   {
      
      private static var stateMovieIdMatch:Object = {
         "15":1,
         "14":2,
         "16":3,
         "17":4,
         "2":5,
         "3":6,
         "4":7,
         "5":8,
         "6":9,
         "7":10,
         "9":11,
         "10":12,
         "11":13,
         "12":14,
         "13":15,
         "18":16,
         "19":17,
         "20":18,
         "21":19,
         "22":20,
         "23":21,
         "24":22,
         "25":23,
         "26":24,
         "27":25,
         "28":26,
         "29":27,
         "30":28,
         "31":29,
         "32":30,
         "33":31,
         "能力下降":32,
         "能力上升":33,
         "34":34,
         "35":35,
         "36":36,
         "37_20":37,
         "38_20":38,
         "39":39,
         "40_1":40,
         "41":41,
         "42_20":42,
         "42_25":42,
         "42_30":42,
         "42_35":42,
         "42_40":42,
         "43_20":43,
         "44":44,
         "45":45,
         "37_25":46,
         "37_28":47,
         "37_30":48,
         "38_25":49,
         "38_28":50,
         "38_30":51,
         "40_2":52,
         "43_25":53,
         "43_30":54,
         "43_35":55,
         "43_40":56,
         "46_20":57,
         "46_25":58,
         "46_28":59,
         "46_30":60,
         "47_20":61,
         "47_25":62,
         "47_28":63,
         "47_30":64,
         "48":65,
         "49":66,
         "50":67,
         "51":68,
         "52":69,
         "53":70,
         "54":71,
         "55":72,
         "56":73,
         "57":74,
         "58":75,
         "59":76,
         "60":77,
         "61":78,
         "62":79,
         "63":80,
         "64":81,
         "65":82,
         "66":83,
         "67":84,
         "68":85,
         "69":86,
         "70":87,
         "71":88,
         "72":89,
         "73":90,
         "74":91,
         "75":92,
         "76":93,
         "77":94,
         "78":95,
         "79":96,
         "80":97,
         "61_1":98,
         "61_2":99,
         "61_3":100,
         "62_1":101,
         "62_2":102,
         "62_3":103,
         "63_20":104,
         "63_35":105,
         "63_50":106,
         "64_100":107,
         "65_150":108,
         "65_200":109,
         "65_250":110,
         "65_300":111,
         "66_75":112,
         "66_100":113,
         "66_150":114,
         "66_225":115,
         "66_325":116,
         "66_500":117,
         "67_1":118,
         "67_2":119,
         "67_3":120,
         "68_0":121,
         "69_0":122,
         "70_0":123,
         "71_0":124,
         "72_0":125,
         "buff_1":126,
         "buff_2":127,
         "buff_3":128,
         "buff_4":129,
         "buff_5":130,
         "buff_6":131,
         "buff_7":132,
         "buff_8":133,
         "buff_9":134,
         "buff_10":135,
         "buff_11":136,
         "buff_12":137,
         "buff_13":138,
         "buff_14":139,
         "buff_15":140,
         "buff_16":141,
         "buff_17":142,
         "buff_18":143,
         "buff_19":144,
         "buff_20":145,
         "buff_21":146,
         "buff_22":147,
         "buff_23":148,
         "buff_24":149,
         "buff_25":150,
         "buff_26":151,
         "buff_27":152,
         "buff_28":153,
         "buff_29":154,
         "buff_30":155,
         "buff_31":156,
         "buff_32":157,
         "buff_33":158,
         "buff_34":159,
         "buff_35":160,
         "buff_36":161,
         "buff_37":162,
         "buff_38":163,
         "buff_39":164,
         "buff_40":165,
         "buff_41":166,
         "buff_42":167,
         "buff_43":168,
         "buff_44":169,
         "buff_45":170,
         "buff_46":171,
         "73_0":172,
         "554_26":174,
         "554_27":174,
         "554_28":174,
         "554_29":174,
         "554_30":174,
         "555_31":175,
         "555_32":175,
         "555_33":175,
         "555_34":175,
         "555_35":175,
         "556_36":176,
         "556_37":176,
         "556_38":176,
         "556_39":176,
         "556_40":176,
         "557_41":177,
         "557_42":177,
         "557_43":177,
         "557_44":177,
         "557_45":177,
         "558_46":178,
         "558_47":178,
         "558_48":178,
         "558_49":178,
         "558_50":178,
         "559_51":179,
         "559_52":179,
         "559_53":179,
         "559_54":179,
         "559_55":179
      };
      
      public static const skillEffectArr:Array = ["14","15","16","17","34","35","36","37_20","38_20","39","40_1","41","42_20","42_25","42_30","42_35","42_40","43_20","44","45","37_25","37_28","37_30","38_25","38_28","38_30","40_2","43_25","43_30","43_35","43_40","46_20","46_25","46_28","46_30","47_20","47_25","47_28","47_30","48","49","63_20","64_100","65_150","65_200","65_250","65_300","67_1","67_2","67_3","68_0","69_0","70_0","71_0","72_0","73_0","buff_1","buff_1","buff_2","buff_3","buff_4","buff_5","buff_6","buff_7","buff_8","buff_9","buff_10","buff_11","buff_12","buff_13","buff_14","buff_15","buff_16","buff_17","buff_18","buff_19","buff_20","buff_21","buff_22","buff_23","buff_24","buff_25","buff_26","buff_27","buff_28","buff_29","buff_30","buff_31","buff_32","buff_33","buff_34","buff_35","buff_36","buff_37","buff_38","buff_39","buff_40","buff_41","buff_42","buff_43","buff_44","buff_45","buff_46","Summoner_3","Summoner_4","554_26","554_27","554_28","554_29","554_30","555_31","555_32","555_33"
      ,"555_34","555_35","556_36","556_37","556_38","556_39","556_40","557_41","557_42","557_43","557_44","557_45","558_46","558_47","558_48","558_49","558_50","559_51","559_52","559_53","559_54","559_55"];
      
      public static const roundEndEffectArr:Array = ["2","3","4","5","6","7","9","10","11","12","13","34","35","36","37_20","38_20","39","40_1","41","42_20","42_25","42_30","42_35","42_40","43_20","44","45","37_25","37_28","37_30","38_25","38_28","38_30","40_2","43_25","43_30","43_35","43_40","46_20","46_25","46_28","46_30","47_20","47_25","47_28","47_30","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","61_1","61_2","61_3","62_1","62_2","62_3","63_20","63_35","63_50","64_100","65_150","65_200","65_250","65_300","66_75","66_100","66_150","66_225","66_325","66_500","67_1","67_2","67_3","68_0","69_0","71_0","72_0","73_0","Summoner_0","Summoner_1","Summoner_2","Summoner_3","Summoner_4","Summoner_0","Summoner_1","Summoner_2","Summoner_5","Summoner_6","Summoner_7","Summoner_8","Summoner_9","554_26","554_27","554_28","554_29","554_30","555_31","555_32","555_33","555_34","555_35","556_36"
      ,"556_37","556_38","556_39","556_40","557_41","557_42","557_43","557_44","557_45","558_46","558_47","558_48","558_49","558_50","559_51","559_52","559_53","559_54","559_55"];
      
      public static const attributeUpEffectArr:Array = ["18","19","20","21","22","23","24","25"];
      
      public static const attributeDownEffectArr:Array = ["26","27","28","29","30","31","32","33"];
      
      public static const skillEndEffectArr:Array = ["14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33"];
      
      public static const fullScreenSkillArr:Array = ["72_0"];
      
      public static const SUMMONER_SKILL_STATE_KEY:String = "Summoner_";
      
      private static const SUMMONER_SKILL_STATE_MOVIE_RES:ResourceObject = new ResourceObject("petfightstatusmovie/summonerskillmovie","mmo.petfightnew.common.SummonerSkillStateMovie_");
      
      public function GetStateMovieUtil()
      {
         super();
      }
      
      public static function checkIsFullScreenSkill(param1:String) : Boolean
      {
         if(checkIsSummonerSkillState(param1))
         {
            return true;
         }
         if(fullScreenSkillArr.indexOf(param1) != -1)
         {
            return true;
         }
         return false;
      }
      
      public static function checkIsSummonerSkillState(param1:String) : Boolean
      {
         return param1.indexOf(SUMMONER_SKILL_STATE_KEY) != -1;
      }
      
      public static function getSummonerSkillFormatState(param1:String) : String
      {
         var _loc2_:Array = param1.split("_");
         return _loc2_[0] + "_" + _loc2_[1];
      }
      
      public static function getSummonerSkillIdByState(param1:String) : int
      {
         var _loc2_:Array = param1.split("_");
         return parseInt(_loc2_[1]);
      }
      
      public static function getStateMovie(param1:int, param2:String, param3:Number, param4:Function) : void
      {
         var stateMovie:MovieClip = null;
         var side:int = 0;
         var url:String = null;
         var cls:String = null;
         var localId:int = param1;
         var state:String = param2;
         var scaleRate:Number = param3;
         var callBack:Function = param4;
         var isSummonerSkillState:Boolean = checkIsSummonerSkillState(state);
         if(isSummonerSkillState)
         {
            state = getSummonerSkillFormatState(state);
            side = FightData.instance.isMySide(localId) ? 0 : 1;
            url = SUMMONER_SKILL_STATE_MOVIE_RES.resPath;
            cls = SUMMONER_SKILL_STATE_MOVIE_RES.clsName + side;
            getStateRes(url,cls,function(param1:MovieClip):void
            {
               setSummonerSkillMovie(state,param1);
               callBack.apply(null,[param1]);
            });
            return;
         }
         stateMovie = FightMcCache.instance.getStateMovie(state);
         if(stateMovie != null)
         {
            callBack.apply(null,[stateMovie]);
            return;
         }
         url = "petfightstatusmovie/statemovie" + stateMovieIdMatch[state];
         cls = "mmo.petfightnew.common.StateMovie" + stateMovieIdMatch[state];
         getStateRes(url,cls,function(param1:MovieClip):void
         {
            param1.scaleX = param1.scaleY = scaleRate;
            stateMovie = BitmapMovieHelper.toSyncBitmapMovie(param1);
            FightMcCache.instance.cacheStateMovie(state,stateMovie);
            callBack.apply(null,[stateMovie]);
         });
      }
      
      private static function getStateRes(param1:String, param2:String, param3:Function) : void
      {
         var mcClass:Class = null;
         var mc:MovieClip = null;
         var url:String = param1;
         var clsName:String = param2;
         var onGetRes:Function = param3;
         if(FightData.instance.applicationDomain.hasDefinition(clsName))
         {
            mcClass = FightData.instance.applicationDomain.getDefinition(clsName) as Class;
            mc = new mcClass() as MovieClip;
            mc.gotoAndStop(1);
            onGetRes.apply(null,[mc]);
         }
         else
         {
            ResScheduler.getResource(url,function(param1:MovieClip):void
            {
               onGetRes.apply(null,[param1]);
            },clsName,null,null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
         }
      }
      
      private static function setSummonerSkillMovie(param1:String, param2:MovieClip) : void
      {
         var _loc3_:int = getSummonerSkillIdByState(param1);
         param2.gotoAndStop(1);
         var _loc4_:MovieClip = param2.getChildByName("mcsub") as MovieClip;
         _loc4_.gotoAndStop(_loc3_ + 1);
      }
      
      public static function isNengLiChangeMv(param1:String) : Boolean
      {
         var _loc2_:Array = ["能力下降","能力上升"];
         return _loc2_.indexOf(param1) >= 0;
      }
   }
}

